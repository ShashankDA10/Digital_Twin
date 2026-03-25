import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_card.dart';
import '../widgets/avatar_glb_view.dart';
import 'appointments/patient_appointments_screen.dart';
import 'medication_screen.dart';
import 'reports_screen.dart';
import 'vitals_screen.dart';
import '../services/auth_service.dart';
import 'auth/auth_wrapper.dart';
import 'patient/patient_qr_screen.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen>
    with SingleTickerProviderStateMixin {
  double _rotation = 0.0;
  int _frontIndex = 0;
  int _tipIndex = 0;
  Offset? _lastPointerPos;
  bool _isPointerDown = false;

  late AnimationController _snapController;
  Animation<double>? _snapAnim;

  bool _isSnapping = false;
  final List<Map<String, dynamic>> _icons = [
    {'icon': Icons.favorite, 'color': AppColors.accentRose, 'label': 'Vitals'},
    {'icon': Icons.description, 'color': AppColors.accentBlue, 'label': 'Reports'},
    {'icon': Icons.local_hospital, 'color': AppColors.accent, 'label': 'Consult'},
    {'icon': Icons.medication,     'color': AppColors.accentAmber,  'label': 'Medication'},
    {'icon': Icons.calendar_month, 'color': AppColors.accentViolet, 'label': 'Appointments'},
  ];

  final List<String> _tips = [
    'Aim for 7-9 hours of sleep to support recovery and focus.',
    'Hydrate consistently; small sips throughout the day add up.',
    'A short walk after meals can help stabilize energy levels.',
    'Keep medications at the same time daily for better adherence.',
    'If your heart rate feels higher than usual, take a few deep breaths.',
    'Stretching for 5 minutes can reduce stiffness and improve circulation.',
    'Review your vitals weekly to notice trends early.',
    'Balanced meals with protein help steady energy and appetite.',
  ];


  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _snapToFront() {
    final step = (2 * pi) / _icons.length;

    double minDelta = double.infinity;
    int closest = 0;
    double closestDelta = 0.0;

    for (int i = 0; i < _icons.length; i++) {
      final angle = _rotation + step * i;
      final delta = _wrapToPi(angle - pi / 2);
      final absDelta = delta.abs();
      if (absDelta < minDelta) {
        minDelta = absDelta;
        closest = i;
        closestDelta = delta;
      }
    }

    final target = _rotation - closestDelta;

    _frontIndex = closest;
    _isSnapping = true;

    _snapAnim = Tween<double>(
      begin: _rotation,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: Curves.easeOutCubic,
      ),
    )
      ..addListener(() {
        setState(() {
          _rotation = _snapAnim!.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _isSnapping = false;
        }
      });

    _snapController
      ..reset()
      ..forward();
  }

  void _applyMagnet() {
    final step = (2 * pi) / _icons.length;
    double minDelta = double.infinity;
    double closestDelta = 0.0;
    int closest = 0;

    for (int i = 0; i < _icons.length; i++) {
      final angle = _rotation + step * i;
      final delta = _wrapToPi(angle - pi / 2);
      final absDelta = delta.abs();
      if (absDelta < minDelta) {
        minDelta = absDelta;
        closestDelta = delta;
        closest = i;
      }
    }

    _frontIndex = closest;

    // Soft magnetic pull when near the front.
    final threshold = step * 0.18;
    if (minDelta < threshold) {
      _rotation -= closestDelta * 0.22;
    }
  }

  double _wrapToPi(double angle) {
    const twoPi = 2 * pi;
    angle = (angle + pi) % twoPi;
    if (angle < 0) angle += twoPi;
    return angle - pi;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final base = min(size.width, size.height);
    final avatarSize = base * 0.46;
    final orbitRadius = avatarSize * 0.78;
    final frontIndex = _findFrontIndex();

    return AppScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Twin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              'Your biometric orbit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white70),
            tooltip: 'My QR Code',
            onPressed: () async {
              final user = await EmailPasswordAuthService.currentAppUser();
              if (user != null && context.mounted) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PatientQrScreen(patient: user),
                ));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            tooltip: 'Sign out',
            onPressed: () async {
              await EmailPasswordAuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _isSnapping
            ? null
            : (event) {
                _isPointerDown = true;
                _lastPointerPos = event.position;
              },
        onPointerMove: _isSnapping
            ? null
            : (event) {
                if (!_isPointerDown || _lastPointerPos == null) return;
                final delta = event.position.dx - _lastPointerPos!.dx;
                _lastPointerPos = event.position;
                setState(() {
                  _rotation -= delta * 0.005;
                  _applyMagnet();
                });
              },
        onPointerUp: _isSnapping
            ? null
            : (_) {
                _isPointerDown = false;
                _lastPointerPos = null;
                _snapToFront();
              },
        onPointerCancel: _isSnapping
            ? null
            : (_) {
                _isPointerDown = false;
                _lastPointerPos = null;
              },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topPad = MediaQuery.of(context).padding.top;
            final bottomPad = MediaQuery.of(context).padding.bottom;
            const tipBarHeight = 84.0;
            const headerHeight = 92.0;
            final availableHeight =
                constraints.maxHeight - topPad - bottomPad - tipBarHeight - headerHeight - 12;
            final availableWidth = constraints.maxWidth;
            final center = Offset(
              availableWidth / 2,
              topPad + headerHeight + availableHeight / 2 + 4,
            );
            final scaledAvatar = min(avatarSize, min(availableHeight * 0.62, availableWidth * 0.7));
            final scaledOrbit = min(orbitRadius, scaledAvatar * 0.72);

            return Stack(
              children: [
                Positioned(
                  left: 20,
                  right: 20,
                  top: topPad + 8,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    glow: true,
                    glowColor: AppColors.accentBlue,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.visibility, color: AppColors.accentBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live twin',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                'Orbit to explore systems',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.muted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                          ),
                          child: Text(
                            'Active',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),
                Positioned(
                  left: center.dx - scaledOrbit * 0.92,
                  top: center.dy - scaledOrbit * 0.92,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      width: scaledOrbit * 1.84,
                      height: scaledOrbit * 1.84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentBlue.withOpacity(0.28),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: center.dx - scaledOrbit * 0.68,
                  top: center.dy - scaledOrbit * 0.68,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      width: scaledOrbit * 1.36,
                      height: scaledOrbit * 1.36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.22),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: center.dx - scaledOrbit * 1.02,
                  top: center.dy - scaledOrbit * 1.02,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      width: scaledOrbit * 2.04,
                      height: scaledOrbit * 2.04,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentViolet.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                ..._buildOrbit(center, scaledOrbit, frontIndex, behind: true, pointerEnabled: false),
                Positioned(
                  left: center.dx - scaledAvatar / 2,
                  top: center.dy - scaledAvatar / 2,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      width: scaledAvatar,
                      height: scaledAvatar,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(
                          color: AppColors.outline.withOpacity(0.6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, -6),
                          ),
                          BoxShadow(
                            color: AppColors.accentBlue.withOpacity(0.35),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const ClipOval(
                        child: AvatarGlbView(),
                      ),
                    ),
                  ),
                ),
                ..._buildOrbit(center, scaledOrbit, frontIndex, behind: false, pointerEnabled: false),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: bottomPad + 16,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _tipIndex = (_tipIndex + 1) % _tips.length;
                      });
                    },
                    child: SizedBox(
                      height: tipBarHeight,
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        glow: true,
                        glowColor: AppColors.accentBlue,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.health_and_safety, color: AppColors.accent),
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: slide, child: child),
                            );
                          },
                          child: Text(
                            _tips[_tipIndex],
                            key: ValueKey(_tipIndex),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.refresh, color: Colors.white54),
                    ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: Stack(
                      children: _buildOrbit(
                        center,
                        scaledOrbit,
                        frontIndex,
                        behind: false,
                        pointerEnabled: true,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildOrbit(
    Offset center,
    double radius,
    int frontIndex, {
    required bool behind,
    required bool pointerEnabled,
  }) {
    final widgets = <Widget>[];
    final step = (2 * pi) / _icons.length;
    const orbitItemWidth = 96.0;

    for (int i = 0; i < _icons.length; i++) {
      final angle = _rotation + step * i;
      final depth = sin(angle);

      if (behind && depth > 0) continue;
      if (!behind && depth <= 0) continue;

      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * 0.45 * sin(angle);

      final t = (depth + 1) / 2;

      final isFront = i == frontIndex && !behind;
      widgets.add(
        Positioned(
          left: x - orbitItemWidth / 2,
          top: y - 20,
          child: SizedBox(
            width: orbitItemWidth,
            child: Column(
              children: [
                Transform.scale(
                  scale: 0.74 + 0.14 * t,
                  child: Opacity(
                    opacity: 0.35 + 0.65 * t,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: pointerEnabled
                          ? () => _handleOrbitTap(_icons[i]['label'] as String)
                          : null,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceElevated.withOpacity(0.9),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                          boxShadow: [
                            if (!behind)
                              BoxShadow(
                                color: (_icons[i]['color'] as Color)
                                    .withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: Transform.translate(
                          offset: (_icons[i]['offset'] as Offset?) ?? Offset.zero,
                          child: Icon(
                            _icons[i]['icon'],
                            color: _icons[i]['color'],
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isFront)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _icons[i]['label'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  int _findFrontIndex() {
    final step = (2 * pi) / _icons.length;
    double minDelta = double.infinity;
    int closest = 0;

    for (int i = 0; i < _icons.length; i++) {
      final angle = _rotation + step * i;
      final delta = _wrapToPi(angle - pi / 2).abs();
      if (delta < minDelta) {
        minDelta = delta;
        closest = i;
      }
    }
    return closest;
  }

  void _handleOrbitTap(String label) {
    switch (label) {
      case 'Vitals':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const VitalsScreen()),
        );
        break;
      case 'Reports':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ReportsScreen()),
        );
        break;
      case 'Medication':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MedicationScreen()),
        );
        break;
      case 'Appointments':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PatientAppointmentsScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consult coming soon.')),
        );
    }
  }

} 
