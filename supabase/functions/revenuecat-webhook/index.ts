import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = { 'content-type': 'application/json' }

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders })
}

function safeEqual(a: string, b: string) {
  if (a.length !== b.length) return false
  let result = 0
  for (let i = 0; i < a.length; i++) result |= a.charCodeAt(i) ^ b.charCodeAt(i)
  return result === 0
}

async function hmacHex(secret: string, value: string) {
  const key = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  )
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(value))
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, '0')).join('')
}

async function validRevenueCatHmac(req: Request, rawBody: string) {
  const secret = Deno.env.get('REVENUECAT_WEBHOOK_HMAC_SECRET') ?? ''
  if (!secret) return true // Authorization header remains mandatory below.
  const header = req.headers.get('x-revenuecat-webhook-signature') ?? ''
  const parts = Object.fromEntries(header.split(',').map((p) => p.split('=', 2)))
  const timestamp = parts.t ?? ''
  const signature = parts.v1 ?? ''
  if (!timestamp || !signature) return false
  const age = Math.abs(Date.now() / 1000 - Number(timestamp))
  if (!Number.isFinite(age) || age > 300) return false
  const expected = await hmacHex(secret, `${timestamp}.${rawBody}`)
  return safeEqual(expected, signature)
}

function toIso(ms: unknown): string | null {
  if (typeof ms !== 'number' || !Number.isFinite(ms)) return null
  return new Date(ms).toISOString()
}

function candidateUserIds(event: Record<string, unknown>): string[] {
  const ids = [event.app_user_id, event.original_app_user_id]
  const aliases = Array.isArray(event.aliases) ? event.aliases : []
  return [...new Set([...ids, ...aliases].filter((v): v is string => typeof v === 'string'))]
}

function looksLikeUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json(405, { error: 'method_not_allowed' })

  const expectedAuth = Deno.env.get('REVENUECAT_WEBHOOK_SECRET') ?? ''
  const auth = req.headers.get('authorization') ?? ''
  if (!expectedAuth || !safeEqual(auth, expectedAuth)) {
    return json(401, { error: 'unauthorized' })
  }

  const rawBody = await req.text()
  if (!(await validRevenueCatHmac(req, rawBody))) {
    return json(401, { error: 'invalid_signature' })
  }

  let body: Record<string, unknown>
  try { body = JSON.parse(rawBody) } catch (_) { return json(400, { error: 'invalid_json' }) }
  const event = (body.event ?? {}) as Record<string, unknown>
  const eventId = String(event.id ?? '')
  const eventType = String(event.type ?? '')
  if (!eventId || !eventType) return json(400, { error: 'missing_event_fields' })

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') ?? '{}').default
  if (!supabaseUrl || !serviceRole) return json(500, { error: 'server_not_configured' })
  const admin = createClient(supabaseUrl, serviceRole, { auth: { persistSession: false } })

  // Idempotency: RevenueCat retries reuse the same event id.
  const { data: existing } = await admin.from('purchase_events').select('event_id').eq('event_id', eventId).maybeSingle()
  if (existing) return json(200, { ok: true, duplicate: true })

  const entitlementIds = Array.isArray(event.entitlement_ids)
    ? event.entitlement_ids.filter((e): e is string => typeof e === 'string')
    : typeof event.entitlement_id === 'string' ? [event.entitlement_id] : []
  const userCandidates = candidateUserIds(event)
  const userId = userCandidates.find(looksLikeUuid)

  await admin.from('purchase_events').insert({
    event_id: eventId,
    app_user_id: String(event.app_user_id ?? ''),
    event_type: eventType,
    product_id: event.product_id ?? null,
    entitlement_ids: entitlementIds,
    store: event.store ?? null,
    environment: event.environment ?? null,
    payload: body,
  })

  // Dashboard TEST can prove delivery without modifying access.
  if (eventType === 'TEST') {
    await admin.from('purchase_events').update({ processed_at: new Date().toISOString() }).eq('event_id', eventId)
    return json(200, { ok: true, test: true })
  }
  if (!userId) {
    return json(200, { ok: true, ignored: 'no_supabase_uuid_alias' })
  }

  const productId = String(event.product_id ?? '')
  const expiration = toIso(event.expiration_at_ms)
  const expirationMs = typeof event.expiration_at_ms === 'number' ? event.expiration_at_ms : null
  const now = Date.now()
  const hasPlus = entitlementIds.includes('plus') || productId === 'teorix_plus_lifetime'
  const hasPro = entitlementIds.includes('pro') || productId === 'teorix_pro_monthly' || productId === 'teorix_pro_yearly'

  const grantEvents = new Set([
    'INITIAL_PURCHASE', 'RENEWAL', 'NON_RENEWING_PURCHASE', 'UNCANCELLATION',
    'SUBSCRIPTION_EXTENDED', 'PURCHASE_REDEEMED', 'REFUND_REVERSED',
  ])
  const revoke = eventType === 'EXPIRATION' ||
    (eventType === 'CANCELLATION' && expirationMs !== null && expirationMs <= now)
  const grant = grantEvents.has(eventType)

  // Cancellation alone normally means auto-renew was turned off; access stays
  // active until EXPIRATION. Billing issues also do not revoke access here.
  if (grant || revoke || eventType === 'CANCELLATION' || eventType === 'BILLING_ISSUE') {
    const { data: current } = await admin.from('entitlements').select('*').eq('user_id', userId).maybeSingle()
    let plusActive = Boolean(current?.plus_active)
    let proActive = Boolean(current?.pro_active)

    if (grant) {
      if (hasPro) proActive = true
      if (hasPlus) plusActive = true
    }
    if (revoke) {
      if (hasPro) proActive = false
      if (hasPlus) plusActive = false
    }
    // Pro includes the ad-free/static Plus experience while active.
    const plan = proActive ? 'pro' : plusActive ? 'plus' : 'free'
    const willRenew = eventType === 'CANCELLATION' ? false :
      ['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'SUBSCRIPTION_EXTENDED'].includes(eventType) ? true : current?.will_renew ?? null

    const { error } = await admin.from('entitlements').upsert({
      user_id: userId,
      plan,
      plus_active: plusActive,
      pro_active: proActive,
      product_id: productId || current?.product_id || null,
      store: event.store ?? current?.store ?? null,
      environment: event.environment ?? current?.environment ?? null,
      will_renew: willRenew,
      expires_at: hasPro ? expiration : current?.expires_at ?? null,
      last_event_id: eventId,
      verified_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id' })
    if (error) return json(500, { error: 'entitlement_update_failed' })
  }

  await admin.from('purchase_events').update({ processed_at: new Date().toISOString() }).eq('event_id', eventId)
  return json(200, { ok: true })
})
