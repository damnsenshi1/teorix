import 'package:flutter/material.dart';
import '../core/theme.dart';

class TxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const TxCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? TxColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .055)),
        ),
        child: child,
      );
}

class TxLogo extends StatelessWidget {
  final double size;
  const TxLogo({super.key, this.size = 30});
  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: -1.4),
          children: const [
            TextSpan(text: 'Teori', style: TextStyle(color: Colors.white)),
            TextSpan(text: 'X', style: TextStyle(color: TxColors.red, fontStyle: FontStyle.italic)),
          ],
        ),
      );
}

class RingProgress extends StatelessWidget {
  final double value;
  final String center;
  final String caption;
  final double size;
  const RingProgress({super.key, required this.value, required this.center, required this.caption, this.size = 116});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: size, height: size, child: CircularProgressIndicator(value: value.clamp(0.0, 1.0).toDouble(), strokeWidth: 10, backgroundColor: Colors.white10, color: TxColors.green)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(center, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            Text(caption, style: const TextStyle(fontSize: 10, color: TxColors.muted)),
          ])
        ]),
      );
}
