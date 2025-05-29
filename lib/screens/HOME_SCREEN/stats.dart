import 'package:flutter/material.dart';
import 'package:my_app/providers/service_provider.dart';
import 'dart:math' as math;

class TemperatureGraphWidget extends StatefulWidget {
  const TemperatureGraphWidget({super.key});
  @override
  State<TemperatureGraphWidget> createState() => _TemperatureGraphWidgetState();
}

class _TemperatureGraphWidgetState extends State<TemperatureGraphWidget>
    with TickerProviderStateMixin {
  late final AnimationController _graphController;
  late final AnimationController _shimmerController;
  late final Animation<double> _graphAnimation;
  late final Animation<double> _shimmerAnimation;

  final CentralizedWeatherService _weatherService = CentralizedWeatherService();

  List<TemperaturePoint> temperatureData = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTemperatureData();
    _weatherService.addListener(_onWeatherDataUpdated);
  }

  @override
  void dispose() {
    _weatherService.removeListener(_onWeatherDataUpdated);
    _graphController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onWeatherDataUpdated() {
    if (mounted) _loadTemperatureData();
  }

  void _initializeAnimations() {
    _graphController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _graphAnimation = _graphController.drive(
      CurveTween(curve: Curves.easeOutCubic),
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_shimmerController);
  }

  Future<void> _loadTemperatureData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final forecastData = await _weatherService.getForecastWeatherData();
      if (!mounted) return;

      final extractedData = forecastData != null
          ? _extractTemperatureData(forecastData)
          : <TemperaturePoint>[];

      setState(() {
        temperatureData = extractedData.isEmpty
            ? _getDefaultTemperatureData()
            : extractedData;
        _isLoading = false;
        _isOffline = extractedData.isEmpty;
        _errorMessage = extractedData.isEmpty
            ? "Using default temperature data"
            : null;
      });
      _startAnimations();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Error loading temperature data: ${e.toString()}";
        temperatureData = _getDefaultTemperatureData();
        _isOffline = true;
      });
      _startAnimations();
    }
  }

  List<TemperaturePoint> _extractTemperatureData(
    Map<String, dynamic> weatherData,
  ) {
    try {
      final hourlyData =
          weatherData['forecast']?['forecastday']?[0]?['hour']
              as List<dynamic>?;
      if (hourlyData == null) return [];

      return hourlyData.map<TemperaturePoint>((hourData) {
        final time = DateTime.fromMillisecondsSinceEpoch(
          hourData['time_epoch'] * 1000,
        );
        return TemperaturePoint(
          hour: time.hour.toDouble(),
          temperature: (hourData['temp_c'] as num).toDouble(),
          time: _formatTime(time),
        );
      }).toList();
    } catch (e) {
      print('Error extracting temperature data: $e');
      return [];
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    return switch (hour) {
      0 => "12 AM",
      12 => "12 PM",
      < 12 => "${hour} AM",
      _ => "${hour - 12} PM",
    };
  }

  List<TemperaturePoint> _getDefaultTemperatureData() => [
    TemperaturePoint(hour: 0, temperature: 18, time: "12 AM"),
    TemperaturePoint(hour: 2, temperature: 16, time: "2 AM"),
    TemperaturePoint(hour: 4, temperature: 14, time: "4 AM"),
    TemperaturePoint(hour: 6, temperature: 15, time: "6 AM"),
    TemperaturePoint(hour: 8, temperature: 18, time: "8 AM"),
    TemperaturePoint(hour: 10, temperature: 22, time: "10 AM"),
    TemperaturePoint(hour: 12, temperature: 28, time: "12 PM"),
    TemperaturePoint(hour: 14, temperature: 32, time: "2 PM"),
    TemperaturePoint(hour: 16, temperature: 30, time: "4 PM"),
    TemperaturePoint(hour: 18, temperature: 26, time: "6 PM"),
    TemperaturePoint(hour: 20, temperature: 22, time: "8 PM"),
    TemperaturePoint(hour: 22, temperature: 20, time: "10 PM"),
    TemperaturePoint(hour: 24, temperature: 18, time: "12 AM"),
  ];

  void _startAnimations() {
    if (!mounted) return;
    _graphController.reset();
    _graphController.forward();
    _shimmerController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildStatusWidget(context, isLoading: true);
    if (_errorMessage != null && temperatureData.isEmpty) {
      return _buildStatusWidget(context, error: _errorMessage);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_graphAnimation, _shimmerAnimation]),
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E).withOpacity(0.8),
                  ],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildTemperatureStats(context),
            const SizedBox(height: 30),
            _buildGraph(context, isDark),
            const SizedBox(height: 20),
            _buildTimeLabels(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget(
    BuildContext context, {
    bool isLoading = false,
    String? error,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text("Loading temperature data..."),
          ] else ...[
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(error ?? "Error loading data"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTemperatureData,
              child: const Text("Retry"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.thermostat, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Temperature Today",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isOffline
                    ? "Cached temperature trend"
                    : "24-hour temperature trend",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final (color, icon, text) = _isOffline
        ? (Colors.orange, Icons.offline_bolt, "Cached")
        : (Colors.green, Icons.trending_up, "Live");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureStats(BuildContext context) {
    if (temperatureData.isEmpty) return const SizedBox.shrink();

    final temps = temperatureData.map((e) => e.temperature).toList();
    final maxTemp = temps.reduce(math.max);
    final minTemp = temps.reduce(math.min);
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;

    final stats = [
      ("Max", maxTemp.toInt(), Colors.red, Icons.keyboard_arrow_up),
      ("Min", minTemp.toInt(), Colors.blue, Icons.keyboard_arrow_down),
      ("Avg", avgTemp.toInt(), Colors.orange, Icons.remove),
    ];

    return Row(
      children:
          stats
              .map(
                (stat) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: stat.$3.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: stat.$3.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(stat.$4, color: stat.$3, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              stat.$1,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${stat.$2}°",
                          style: TextStyle(
                            color: stat.$3,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList()
            ..removeLast(), // Remove margin from last item
    );
  }

  Widget _buildGraph(BuildContext context, bool isDark) {
    if (temperatureData.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: GridPainter(isDark: isDark)),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: TemperatureGradientPainter(
                data: temperatureData,
                progress: _graphAnimation.value,
                isDark: isDark,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: TemperatureCurvePainter(
                data: temperatureData,
                progress: _graphAnimation.value,
                shimmerProgress: _shimmerAnimation.value,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLabels(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabels = temperatureData.isNotEmpty && temperatureData.length >= 5
        ? _getActualTimeLabels()
        : ["12 AM", "6 AM", "12 PM", "6 PM", "12 AM"];

    return Row(
      children: timeLabels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  List<String> _getActualTimeLabels() {
    final step = temperatureData.length ~/ 4;
    return [
      temperatureData[0].time,
      temperatureData[step].time,
      temperatureData[step * 2].time,
      temperatureData[step * 3].time,
      temperatureData.last.time,
    ];
  }
}

class TemperaturePoint {
  final double hour;
  final double temperature;
  final String time;

  TemperaturePoint({
    required this.hour,
    required this.temperature,
    required this.time,
  });
}

class GridPainter extends CustomPainter {
  final bool isDark;

  GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final ratio = i / 4;
      canvas.drawLine(
        Offset(0, ratio * size.height),
        Offset(size.width, ratio * size.height),
        paint,
      );
      canvas.drawLine(
        Offset(ratio * size.width, 0),
        Offset(ratio * size.width, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TemperatureGradientPainter extends CustomPainter {
  final List<TemperaturePoint> data;
  final double progress;
  final bool isDark;

  TemperatureGradientPainter({
    required this.data,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || progress == 0) return;

    final temps = data.map((e) => e.temperature);
    final (maxTemp, minTemp) = (temps.reduce(math.max), temps.reduce(math.min));
    final path = _createSmoothPath(size, maxTemp, minTemp);

    path.lineTo(size.width * progress, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withOpacity(0.3),
          Colors.orange.withOpacity(0.2),
          Colors.red.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  Path _createSmoothPath(Size size, double maxTemp, double minTemp) {
    final path = Path();
    final visibleCount = (data.length * progress).round();
    if (visibleCount == 0) return path;

    final points = List.generate(visibleCount, (i) {
      final point = data[i];
      final x = (i / (data.length - 1)) * size.width;
      final normalizedTemp = (maxTemp - minTemp) > 0
          ? (point.temperature - minTemp) / (maxTemp - minTemp)
          : 0.5;
      final y = size.height - (normalizedTemp * (size.height - 40)) - 20;
      return Offset(x, y);
    });

    if (points.isEmpty) return path;

    path.moveTo(0, size.height);
    path.lineTo(points.first.dx, points.first.dy);

    if (points.length > 2) {
      for (int i = 1; i < points.length; i++) {
        final current = points[i];
        if (i == points.length - 1) {
          path.lineTo(current.dx, current.dy);
        } else {
          final next = points[i + 1];
          path.quadraticBezierTo(
            current.dx,
            current.dy,
            (current.dx + next.dx) / 2,
            (current.dy + next.dy) / 2,
          );
        }
      }
    } else if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant TemperatureGradientPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class TemperatureCurvePainter extends CustomPainter {
  final List<TemperaturePoint> data;
  final double progress;
  final double shimmerProgress;
  final bool isDark;

  TemperatureCurvePainter({
    required this.data,
    required this.progress,
    required this.shimmerProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || progress == 0) return;

    final temps = data.map((e) => e.temperature);
    final path = _createSmoothPath(
      size,
      temps.reduce(math.max),
      temps.reduce(math.min),
    );

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    if (progress > 0.5) {
      final shimmerPaint = Paint()
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.4),
            Colors.transparent,
          ],
          stops: [
            math.max(0.0, shimmerProgress - 0.1),
            shimmerProgress,
            math.min(1.0, shimmerProgress + 0.1),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, shimmerPaint);
    }
  }

  Path _createSmoothPath(Size size, double maxTemp, double minTemp) {
    final path = Path();
    final visibleCount = (data.length * progress).round();
    if (visibleCount == 0) return path;

    final points = List.generate(visibleCount, (i) {
      final point = data[i];
      final x = (i / (data.length - 1)) * size.width;
      final normalizedTemp = (maxTemp - minTemp) > 0
          ? (point.temperature - minTemp) / (maxTemp - minTemp)
          : 0.5;
      final y = size.height - (normalizedTemp * (size.height - 40)) - 20;
      return Offset(x, y);
    });

    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);

    if (points.length > 2) {
      for (int i = 1; i < points.length; i++) {
        final current = points[i];
        if (i == points.length - 1) {
          path.lineTo(current.dx, current.dy);
        } else {
          final next = points[i + 1];
          path.quadraticBezierTo(
            current.dx,
            current.dy,
            (current.dx + next.dx) / 2,
            (current.dy + next.dy) / 2,
          );
        }
      }
    } else if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant TemperatureCurvePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.shimmerProgress != shimmerProgress;
}
