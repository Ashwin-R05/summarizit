import 'package:flutter/material.dart';
import 'package:summarizit/theme/theme_provider.dart';

/// An animated card that displays summary bullet points with staggered
/// fade-in, theme-aware glassmorphism, and numbered bullet styling.
class SummaryCard extends StatefulWidget {
  final List<String> bullets;
  final bool isDark;

  const SummaryCard({
    super.key,
    required this.bullets,
    this.isDark = true,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.bullets.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _fadeAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .map((a) => Tween<double>(begin: 0, end: 1).animate(a))
        .toList();

    _slideAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .map((a) =>
            Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
                .animate(a))
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bullets != widget.bullets) {
      _disposeControllers();
      _initAnimations();
    }
  }

  void _disposeControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardOverlay(dark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(dark), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(dark),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Summary',
                style: TextStyle(
                  color: AppColors.text(dark),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.bullets.length} points',
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // ── Bullet points ──
          ...List.generate(widget.bullets.length, (i) {
            return SlideTransition(
              position: _slideAnimations[i],
              child: FadeTransition(
                opacity: _fadeAnimations[i],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Numbered badge
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.03)
                                : AppColors.lightBg.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border(dark)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            widget.bullets[i],
                            style: TextStyle(
                              color: AppColors.text(dark)
                                  .withValues(alpha: 0.88),
                              fontSize: 14.5,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
