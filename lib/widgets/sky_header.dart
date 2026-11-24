import 'dart:math';

import 'package:flutter/material.dart';

/// Bandeau de ciel : à chaque avancée du temps, le soleil se couche, la lune
/// passe, puis le soleil revient. Le halo déborde sur la page.
class SkyHeader extends StatelessWidget {
  /// Avancement du cycle : de 0 à 1 = un tour complet (jour, nuit, jour).
  final Animation<double> cycle;
  final Widget child;
  final double height;

  const SkyHeader({
    super.key,
    required this.cycle,
    required this.child,
    this.height = 150,
  });

  /// Jusqu'où la lumière déborde autour de la carte (en pixels).
  static const _spill = EdgeInsets.fromLTRB(16, 110, 16, 140);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        height: height,
        // Clip.none : le halo peut être dessiné hors de la carte.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Le halo, plus grand que la carte : dessiné en premier, il
            // passe sous le reste de la page.
            Positioned(
              left: -_spill.left,
              right: -_spill.right,
              top: -_spill.top,
              bottom: -_spill.bottom,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SkyGlowPainter(cycle, cardInsets: _spill),
                ),
              ),
            ),
            // 2. La carte de ciel.
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // `repaint: cycle` (dans le peintre) : redessiné à chaque
                    // image de l'animation, sans reconstruire les widgets.
                    CustomPaint(painter: SkyPainter(cycle), willChange: true),
                    Center(child: child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Position dans la journée pour un avancement [t] du cycle.
double dayPhase(double t) => (0.25 + t) % 1.0;

/// Luminosité du ciel : 1 = plein jour, −1 = pleine nuit, 0 = crépuscule.
double skyBrightness(double phase) => sin(2 * pi * phase);

/// Position du soleil (le jour) ou de la lune (la nuit) dans un ciel de
/// taille [size] : un arc de cercle de gauche à droite.
Offset celestialPosition(double phase, Size size) {
  final along = phase < 0.5 ? phase * 2 : (phase - 0.5) * 2; // 0 → 1
  return Offset(
    size.width * (0.1 + 0.8 * along),
    size.height * (0.9 - 0.75 * sin(pi * along)),
  );
}

/// Couleurs du ciel (haut, bas) pour une luminosité [light].
(Color, Color) skyColors(double light) {
  const dayTop = Color(0xFF3D9BF0), dayBottom = Color(0xFFBDE5FF);
  const duskTop = Color(0xFF5B4FB8), duskBottom = Color(0xFFFFA86B);
  const nightTop = Color(0xFF040A22), nightBottom = Color(0xFF17306E);
  return light >= 0
      ? (
          Color.lerp(duskTop, dayTop, light)!,
          Color.lerp(duskBottom, dayBottom, light)!,
        )
      : (
          Color.lerp(duskTop, nightTop, -light)!,
          Color.lerp(duskBottom, nightBottom, -light)!,
        );
}

/// Couleur de la lumière : dorée le jour, orangée au crépuscule, bleutée
/// la nuit.
Color lightColor(double light) => light >= 0
    ? Color.lerp(const Color(0xFFFF9A50), const Color(0xFFFFD36B), light)!
    : Color.lerp(const Color(0xFFFF9A50), const Color(0xFF8FB0FF), -light)!;

/// Le ciel, dans la carte.
class SkyPainter extends CustomPainter {
  final Animation<double> cycle;

  SkyPainter(this.cycle) : super(repaint: cycle);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = dayPhase(cycle.value);
    final light = skyBrightness(phase);
    final rect = Offset.zero & size;
    final isDay = phase < 0.5;
    final body = celestialPosition(phase, size);
    final r = size.height * 0.11; // rayon de l'astre

    // 1. Le ciel : un dégradé du haut vers l'horizon.
    final (top, bottom) = skyColors(light);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );

    // 2. Lever et coucher : l'horizon s'embrase sous l'astre.
    final dusk = 1 - light.abs(); // 1 au crépuscule, 0 à midi ou minuit
    if (dusk > 0.05) {
      _glow(
        canvas,
        Offset(body.dx, size.height),
        size.width * 0.6,
        const Color(0xFFFF8A4C),
        0.55 * dusk,
      );
    }

    // 3. Les étoiles scintillent la nuit.
    if (light < 0) {
      final random = Random(42); // même graine → mêmes étoiles à chaque image
      for (var i = 0; i < 40; i++) {
        final twinkle = 0.55 + 0.45 * sin(cycle.value * 2 * pi * 3 + i);
        canvas.drawCircle(
          Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height * 0.7,
          ),
          0.6 + random.nextDouble(),
          Paint()..color = Colors.white.withValues(alpha: -light * twinkle),
        );
      }
    }

    // 4. Le soleil ou la lune, avec leur lumière.
    if (isDay) {
      _sun(canvas, body, r, cycle.value);
    } else {
      _moon(canvas, body, r);
    }

    // 5. Des collines au premier plan, plus sombres que l'horizon.
    _hills(canvas, size, bottom);

    // 6. Un fin liseré clair : la carte semble faite de verre.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(28)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.25),
    );
  }

  /// Disque de lumière qui s'efface vers ses bords.
  static void _glow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  static void _sun(Canvas canvas, Offset c, double r, double t) {
    // Couronne lumineuse.
    _glow(canvas, c, r * 4, const Color(0xFFFFE9A8), 0.6);
    // Rayons qui tournent lentement.
    final ray = Paint()
      ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.45)
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 12; k++) {
      final angle = k * pi / 6 + t * pi;
      final length = r * (2.0 + 0.3 * sin(t * 2 * pi * 2 + k));
      final dir = Offset(cos(angle), sin(angle));
      canvas.drawLine(c + dir * (r * 1.35), c + dir * length, ray);
    }
    // Le disque : plus clair au centre.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFFB300)],
          stops: [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  static void _moon(Canvas canvas, Offset c, double r) {
    // Halo argenté.
    _glow(canvas, c, r * 3.2, const Color(0xFFCFE0FF), 0.45);
    // Le disque, éclairé par le haut à gauche.
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.35),
          colors: [Color(0xFFFFFFF4), Color(0xFFDCDAC4)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Quelques cratères.
    final crater = Paint()..color = const Color(0x1F000000);
    for (final (dx, dy, size) in const [
      (-0.30, -0.20, 0.22),
      (0.28, 0.12, 0.15),
      (-0.05, 0.38, 0.11),
    ]) {
      canvas.drawCircle(c + Offset(dx * r, dy * r), size * r, crater);
    }
  }

  static void _hills(Canvas canvas, Size size, Color horizon) {
    const navy = Color(0xFF0B1424);
    final h = size.height;
    final w = size.width;
    // Colline lointaine, puis colline proche (plus sombre).
    final far = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.25, h * 0.74, w * 0.55, h * 0.84)
      ..quadraticBezierTo(w * 0.8, h * 0.92, w, h * 0.8)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, Paint()..color = Color.lerp(horizon, navy, 0.25)!);
    final near = Path()
      ..moveTo(0, h * 0.94)
      ..quadraticBezierTo(w * 0.4, h * 0.84, w * 0.7, h * 0.93)
      ..quadraticBezierTo(w * 0.88, h * 0.98, w, h * 0.9)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(near, Paint()..color = Color.lerp(horizon, navy, 0.45)!);
  }

  @override
  bool shouldRepaint(SkyPainter oldDelegate) => oldDelegate.cycle != cycle;
}

/// La lumière du soleil ou de la lune qui déborde de la carte et éclaire
/// le fond de la page.
class SkyGlowPainter extends CustomPainter {
  final Animation<double> cycle;

  /// Marges entre le bord de ce dessin et la carte de ciel.
  final EdgeInsets cardInsets;

  SkyGlowPainter(this.cycle, {required this.cardInsets})
    : super(repaint: cycle);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = dayPhase(cycle.value);
    final light = skyBrightness(phase);
    final card = cardInsets.deflateRect(Offset.zero & size);
    final body = card.topLeft + celestialPosition(phase, card.size);
    // Plus intense le jour, plus discrète la nuit.
    final opacity = light >= 0 ? 0.32 + 0.16 * light : 0.32 - 0.08 * -light;
    final radius = card.width;
    canvas.drawCircle(
      body,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            lightColor(light).withValues(alpha: opacity),
            lightColor(light).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: body, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(SkyGlowPainter oldDelegate) => oldDelegate.cycle != cycle;
}
