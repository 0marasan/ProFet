import 'package:flutter/material.dart';

class CustomLinearProgressBar extends StatefulWidget {
  final double percentage;
  final String label;
  final double width;
  final double height;
  final bool showPercentage;
  final TextStyle? labelStyle;
  final TextStyle? percentageStyle;
  final Color? backgroundColor;
  final Color? color;
  final Map<double, Color>? thresholdColors;
  final Duration animationDuration;
  final Curve animationCurve;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const CustomLinearProgressBar({
    Key? key,
    required this.percentage,
    required this.label,
    this.width = 200.0,
    this.height = 8.0,
    this.showPercentage = true,
    this.labelStyle,
    this.percentageStyle,
    this.backgroundColor,
    this.color,
    this.thresholdColors,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.animationCurve = Curves.easeInOutCubic,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
    this.borderRadius,
  }) : super(key: key);

  @override
  State<CustomLinearProgressBar> createState() => _CustomLinearProgressBarState();
}

class _CustomLinearProgressBarState extends State<CustomLinearProgressBar>
    with SingleTickerProviderStateMixin {
  late double _previousPercentage;
  late double _clampedPercentage;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _previousPercentage = widget.percentage.clamp(0.0, 100.0);
    _clampedPercentage = widget.percentage.clamp(0.0, 100.0);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomLinearProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previousPercentage = oldWidget.percentage.clamp(0.0, 100.0);
    _clampedPercentage = widget.percentage.clamp(0.0, 100.0);
  }

  Color _getProgressColor(double percentage) {
    if (widget.color != null) return widget.color!;

    if (widget.thresholdColors != null) {
      final sortedThresholds = widget.thresholdColors!.keys.toList()..sort();
      for (final threshold in sortedThresholds.reversed) {
        if (percentage >= threshold) {
          return widget.thresholdColors![threshold]!;
        }
      }
      return widget.thresholdColors!.values.first;
    }

    // Default modern gradient based on percentage
    if (percentage >= 75) {
      return const Color(0xFF4CAF50); // Success Green
    } else if (percentage >= 50) {
      return const Color(0xFF2196F3); // Info Blue
    } else if (percentage >= 25) {
      return const Color(0xFFFFA726); // Warning Orange
    } else {
      return const Color(0xFFE57373); // Error Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultLabelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white.withOpacity(0.9),
    );
    final defaultPercentageStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white.withOpacity(0.9),
    );

    final progressColor = _getProgressColor(_clampedPercentage);

    return Semantics(
      label: '${widget.label}: ${_clampedPercentage.toStringAsFixed(1)}%',
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showPercentage)
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: widget.percentageStyle ?? defaultPercentageStyle!,
                child: Text(
                  '${_clampedPercentage.toStringAsFixed(1)}%',
                ),
              ),
            const SizedBox(height: 8.0),
            Stack(
              children: [
                // Animated background glow
                if (_clampedPercentage > 75)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withOpacity(0.3 * _glowAnimation.value),
                              blurRadius: 8.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Main progress bar
                ClipRRect(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
                  child: Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ?? Colors.white.withOpacity(0.1),
                    ),
                    child: Stack(
                      children: [
                        // Progress fill
                        TweenAnimationBuilder<double>(
                          duration: widget.animationDuration,
                          curve: widget.animationCurve,
                          tween: Tween<double>(
                            begin: _previousPercentage / 100,
                            end: _clampedPercentage / 100,
                          ),
                          builder: (context, value, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    progressColor,
                                    progressColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Shimmer effect
                        if (_clampedPercentage > 0)
                          TweenAnimationBuilder<double>(
                            duration: widget.animationDuration,
                            curve: widget.animationCurve,
                            tween: Tween<double>(
                              begin: _previousPercentage / 100,
                              end: _clampedPercentage / 100,
                            ),
                            builder: (context, value, _) => FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.0),
                                        Colors.white.withOpacity(0.2 * _glowAnimation.value),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}