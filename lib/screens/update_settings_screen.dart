import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/app_update_service.dart';
import '../services/app_settings_service.dart';
import '../widgets/tx_widgets.dart';

class UpdateSettingsScreen extends StatefulWidget {
  const UpdateSettingsScreen({super.key});
  @override State<UpdateSettingsScreen> createState()=>_UpdateSettingsScreenState();
}
class _UpdateSettingsScreenState extends State<UpdateSettingsScreen> {
  final u=AppUpdateService.instance;
  String _t(String tr,String nl,String de,String en)=>switch(AppSettingsService.instance.locale){'nl'=>nl,'de'=>de,'en'=>en,_=>tr};
  @override void initState(){super.initState();u.addListener(_refresh);}
  @override void dispose(){u.removeListener(_refresh);super.dispose();}
  void _refresh(){if(mounted)setState((){});}
  String get _last => u.lastCheck==null?_t('Henüz kontrol edilmedi','Nog niet gecontroleerd','Noch nicht geprüft','Not checked yet'):'${u.lastCheck!.day.toString().padLeft(2,'0')}.${u.lastCheck!.month.toString().padLeft(2,'0')}.${u.lastCheck!.year} ${u.lastCheck!.hour.toString().padLeft(2,'0')}:${u.lastCheck!.minute.toString().padLeft(2,'0')}';
  @override Widget build(BuildContext context){
    final r=u.available;
    return Scaffold(appBar:AppBar(title:Text(_t('Uygulama Güncellemeleri','App-updates','App-Updates','App Updates'))),body:ListView(padding:const EdgeInsets.all(16),children:[
      TxCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[const Icon(Icons.system_update_rounded,color:TxColors.blue,size:30),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('TeoriX ${u.currentVersion.isEmpty?'':u.currentVersion}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),Text(_t('Build ${u.currentBuild} • Son kontrol: $_last','Build ${u.currentBuild} • Laatst gecontroleerd: $_last','Build ${u.currentBuild} • Zuletzt geprüft: $_last','Build ${u.currentBuild} • Last check: $_last'),style:const TextStyle(color:TxColors.muted,fontSize:11))]))]),
        const SizedBox(height:14),
        SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:u.checking?null:()async=>u.checkForUpdates(),icon:u.checking?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.refresh_rounded),label:Text(_t('Şimdi kontrol et','Nu controleren','Jetzt prüfen','Check now')))),
      ])),
      const SizedBox(height:12),
      TxCard(child:Column(children:[SwitchListTile(contentPadding:EdgeInsets.zero,value:u.autoDownload,onChanged:u.setAutoDownload,title:Text(_t('Güncellemeleri otomatik indir','Updates automatisch downloaden','Updates automatisch herunterladen','Download updates automatically'),style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(_t('Yeni APK TeoriX içinde indirilir. Chrome açılmaz.','Nieuwe APK wordt in TeoriX gedownload. Chrome wordt niet geopend.','Neue APK wird in TeoriX heruntergeladen. Chrome wird nicht geöffnet.','The new APK downloads inside TeoriX. Chrome is not opened.'),style:const TextStyle(color:TxColors.muted,fontSize:11))),SwitchListTile(contentPadding:EdgeInsets.zero,value:u.wifiOnly,onChanged:u.setWifiOnly,title:Text(_t('Yalnızca Wi‑Fi ile indir','Alleen via wifi','Nur über WLAN','Download on Wi‑Fi only'),style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(_t('Mobil veri kullanımını azaltır','Bespaart mobiele data','Spart mobile Daten','Reduces mobile data use'),style:const TextStyle(color:TxColors.muted,fontSize:11)))])),
      if(r!=null)...[const SizedBox(height:12),TxCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(r.title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))),Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:TxColors.blue.withValues(alpha:.14),borderRadius:BorderRadius.circular(99)),child:Text('v${r.versionName}',style:const TextStyle(color:TxColors.blue,fontWeight:FontWeight.w900)))]),if(r.notes.isNotEmpty)...[const SizedBox(height:9),Text(r.notes,style:const TextStyle(color:TxColors.muted,height:1.4))],if(u.downloading)...[const SizedBox(height:14),LinearProgressIndicator(value:u.progress>0?u.progress:null),const SizedBox(height:6),Text('${(u.progress*100).clamp(0,100).toStringAsFixed(0)}%',style:const TextStyle(color:TxColors.muted))],const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:u.downloading?null:()=>u.installOrOpenStore(r),icon:const Icon(Icons.download_for_offline_rounded),label:Text(r.delivery=='store'?_t('Play Store’da Aç','Openen in Play Store','Im Play Store öffnen','Open in Play Store'):_t('İndir ve Kur','Downloaden en installeren','Herunterladen & installieren','Download & Install'))))]))] else if(!u.checking)...[const SizedBox(height:12),TxCard(child:Row(children:[const Icon(Icons.verified_rounded,color:Colors.green),const SizedBox(width:10),Expanded(child:Text(_t('TeoriX güncel. Yeni sürüm olduğunda burada görünecek.','TeoriX is up-to-date. Nieuwe versies verschijnen hier.','TeoriX ist aktuell. Neue Versionen erscheinen hier.','TeoriX is up to date. New versions will appear here.'),style:const TextStyle(color:TxColors.muted))) ]))],
      if(u.error!=null)...[const SizedBox(height:12),TxCard(child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.info_outline_rounded,color:Colors.orange),const SizedBox(width:10),Expanded(child:Text(u.error!,style:const TextStyle(color:TxColors.muted)))]))],
      const SizedBox(height:14),Text(_t('Not: Android güvenliği nedeniyle indirme otomatik olabilir; ancak kurulumun son “Yükle” onayı sistem ekranında kullanıcı tarafından verilir.','Opmerking: de download kan automatisch verlopen, maar Android vereist een laatste installatiebevestiging.','Hinweis: Der Download kann automatisch erfolgen, Android verlangt jedoch eine letzte Installationsbestätigung.','Note: download can be automatic, but Android requires a final install confirmation.'),style:const TextStyle(color:TxColors.muted,fontSize:11,height:1.4),textAlign:TextAlign.center)
    ]));
  }
}
