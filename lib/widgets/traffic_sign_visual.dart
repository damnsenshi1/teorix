import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/traffic_sign.dart';

class TrafficSignVisual extends StatelessWidget {
  final TrafficSignInfo sign;
  final double size;

  const TrafficSignVisual({super.key, required this.sign, this.size = 76});

  @override
  Widget build(BuildContext context) {
    final symbol = sign.symbol.isEmpty ? _fallbackSymbol(sign.shape) : sign.symbol;
    switch (sign.shape) {
      case 'octagon':
        return ClipPath(
          clipper: _OctagonClipper(),
          child: _box(symbol, TxColors.red, Colors.white),
        );
      case 'yield':
      case 'warning':
        return SizedBox(
          width: size * 1.03,
          height: size * .95,
          child: CustomPaint(
            painter: _TrianglePainter(
              fill: sign.shape == 'yield' ? Colors.white : const Color(0xFFFFF7E8),
              border: TxColors.red,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: size * .1),
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: size * .29,
                  ),
                ),
              ),
            ),
          ),
        );
      case 'mandatory':
        return _circle(symbol, TxColors.blue, Colors.white);
      case 'speed':
        return _ringCircle(symbol);
      case 'prohibition':
        return _prohibitionCircle(symbol);
      case 'no_entry':
        return _noEntry();
      case 'no_parking':
      case 'no_stop':
        return _circle(
          sign.shape == 'no_stop' ? '✕' : '/',
          const Color(0xFF174A9B),
          TxColors.red,
          border: TxColors.red,
        );
      case 'info':
        return _box(symbol, const Color(0xFF1953A6), Colors.white);
      default:
        return _box(symbol, const Color(0xFF1B2940), Colors.white);
    }
  }

  Widget _box(String text, Color bg, Color fg) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size * .18),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fg,
            fontSize: text.length > 3 ? size * .21 : size * .33,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

  Widget _circle(String text, Color bg, Color fg, {Color? border}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: border ?? Colors.white24,
            width: border == null ? 2 : size * .065,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: fg, fontSize: size * .36, fontWeight: FontWeight.w900),
        ),
      );

  Widget _prohibitionCircle(String text) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: TxColors.red, width: size * .08),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.black87, fontSize: size * .29, fontWeight: FontWeight.w900),
        ),
      );

  Widget _ringCircle(String text) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: TxColors.red, width: size * .09),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.black, fontSize: size * .30, fontWeight: FontWeight.w900),
        ),
      );

  Widget _noEntry() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: TxColors.red, shape: BoxShape.circle),
        child: Container(
          width: size * .66,
          height: size * .17,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * .04)),
        ),
      );

  String _fallbackSymbol(String shape) => switch (shape) {
        'warning' => '!',
        'yield' => '',
        'mandatory' => '→',
        'info' => 'i',
        _ => '',
      };
}

class _OctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height, d = w * .28;
    return Path()
      ..moveTo(d, 0)
      ..lineTo(w - d, 0)
      ..lineTo(w, d)
      ..lineTo(w, h - d)
      ..lineTo(w - d, h)
      ..lineTo(d, h)
      ..lineTo(0, h - d)
      ..lineTo(0, d)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TrianglePainter extends CustomPainter {
  final Color fill;
  final Color border;
  const _TrianglePainter({required this.fill, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height - 4)
      ..lineTo(4, 4)
      ..lineTo(size.width - 4, 4)
      ..close();
    canvas.drawPath(path, Paint()..color = border..style = PaintingStyle.fill);
    final inset = size.width * .13;
    final inner = Path()
      ..moveTo(size.width / 2, size.height - inset)
      ..lineTo(inset, inset * .75)
      ..lineTo(size.width - inset, inset * .75)
      ..close();
    canvas.drawPath(inner, Paint()..color = fill..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}
