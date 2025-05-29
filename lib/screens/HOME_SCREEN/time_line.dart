import 'package:flutter/material.dart';
import 'package:my_app/providers/service_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WeatherTimeline extends StatefulWidget {
  const WeatherTimeline({super.key});

  @override
  State<WeatherTimeline> createState() => _WeatherTimelineState();
}

class _WeatherTimelineState extends State<WeatherTimeline>
    with TickerProviderStateMixin {
  final CentralizedWeatherService _weatherService = CentralizedWeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0;
  bool _isOffline = false;
  late AnimationController _tabController, _contentController;
  late Animation<double> _tabAnimation, _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _tabAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _tabController, curve: Curves.easeInOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeInOut),
    );
    _weatherService.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    _weatherService.removeListener(_loadData);
    _tabController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isOffline) _buildOfflineIndicator(),
        _buildTabRow(),
        const SizedBox(height: 20),
        _buildContent(),
      ],
    ),
  );

  Widget _buildOfflineIndicator() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.orange.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.offline_bolt, size: 16, color: Colors.orange),
        SizedBox(width: 8),
        Text(
          "Using cached data",
          style: TextStyle(color: Colors.orange, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildTabRow() {
    final tabs = ["Today", "Tomorrow", "Next 10 days"];
    return AnimatedBuilder(
      animation: _tabAnimation,
      builder: (context, child) => Row(
        children: List.generate(
          tabs.length,
          (i) => Padding(
            padding: EdgeInsets.only(right: i < tabs.length - 1 ? 24 : 0),
            child: GestureDetector(
              onTap: _weatherData != null ? () => _selectTab(i) : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == i
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: _selectedTab == i
                      ? Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        )
                      : null,
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(
                      _selectedTab == i ? 1 : 0.6,
                    ),
                    fontSize: 16,
                    fontWeight: _selectedTab == i
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (_selectedTab != index) {
      _contentController.reverse().then((_) {
        setState(() => _selectedTab = index);
        _contentController.forward();
      });
      _tabController.forward().then((_) => _tabController.reverse());
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildStateWidget(Icons.refresh, "Loading weather data...", null);
    }
    if (_errorMessage != null) {
      return _buildStateWidget(Icons.error_outline, _errorMessage!, Colors.red);
    }
    if (_weatherData == null) {
      return _buildStateWidget(
        Icons.cloud_off,
        "No weather data available",
        Colors.grey,
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: [
        _buildTodayView(),
        _buildTomorrowView(),
        _buildNext10DaysView(),
      ][_selectedTab],
    );
  }

  Widget _buildStateWidget(IconData icon, String message, Color? color) =>
      Center(
        child: Column(
          children: [
            _isLoading
                ? CircularProgressIndicator()
                : Icon(icon, size: 48, color: color),
            SizedBox(height: 16),
            Text(message),
            if (!_isLoading) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: Text(_errorMessage != null ? "Retry" : "Refresh"),
              ),
            ],
          ],
        ),
      );

  void _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isOffline = false;
    });

    try {
      final hasInternet =
          await Connectivity().checkConnectivity() != ConnectivityResult.none;
      final data = await _weatherService.getForecastWeatherData();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (data != null) {
            _weatherData = data;
            _isOffline = !hasInternet;
            _contentController.forward();
          } else {
            _errorMessage =
                "Failed to load weather data. Please check your internet connection.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error loading weather data: ${e.toString()}";
        });
      }
    }
  }

  Widget _buildTodayView() {
    final hourlyData =
        _weatherData!['forecast']['forecastday'][0]['hour'] as List<dynamic>;
    final now = DateTime.now();
    final futureHours = hourlyData
        .where(
          (h) => DateTime.fromMillisecondsSinceEpoch(
            h['time_epoch'] * 1000,
          ).isAfter(now),
        )
        .take(7)
        .toList();
    final displayHours = futureHours.isEmpty
        ? hourlyData.take(7).toList()
        : futureHours;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: displayHours.map((h) => _buildHourlyItem(h)).toList(),
      ),
    );
  }

  Widget _buildTomorrowView() {
    if (_weatherData!['forecast']['forecastday'].length < 2) {
      return Text("No forecast data available for tomorrow");
    }
    final hourlyData =
        _weatherData!['forecast']['forecastday'][1]['hour'] as List<dynamic>;
    final selectedHours = <dynamic>[];
    for (int i = 0; i < hourlyData.length && selectedHours.length < 8; i += 3) {
      selectedHours.add(hourlyData[i]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: selectedHours.map((h) => _buildHourlyItem(h)).toList(),
      ),
    );
  }

  Widget _buildNext10DaysView() => Column(
    children: (_weatherData!['forecast']['forecastday'] as List<dynamic>)
        .map((day) => _buildDailyItem(day))
        .toList(),
  );

  Widget _buildHourlyItem(Map<String, dynamic> hourData) {
    final theme = Theme.of(context);
    final time = DateTime.fromMillisecondsSinceEpoch(
      hourData['time_epoch'] * 1000,
    );
    final timeStr =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    final icon = _getWeatherIcon(
      hourData['condition']['code'],
      hourData['is_day'] == 1,
    );

    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Text(
            timeStr,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: _getIconColor(icon), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            "${hourData['humidity']}%",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${hourData['temp_c'].round()}°",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyItem(Map<String, dynamic> dayData) {
    final theme = Theme.of(context);
    final date = DateTime.fromMillisecondsSinceEpoch(
      dayData['date_epoch'] * 1000,
    );
    final day = dayData['day'];
    final icon = _getWeatherIcon(day['condition']['code'], true);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _getDayName(date),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(icon, color: _getIconColor(icon), size: 28),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        "${day['mintemp_c'].round()}°",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${day['maxtemp_c'].round()}°",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                Icons.water_drop,
                "${day['avghumidity']}%",
                "Humidity",
              ),
              _buildInfoChip(
                Icons.air,
                "${day['maxwind_kph'].round()} km/h",
                "Wind",
              ),
              _buildInfoChip(
                Icons.visibility,
                "${day['avgvis_km'].round()} km",
                "Visibility",
              ),
              _buildInfoChip(
                Icons.thermostat,
                "${day['avgtemp_c'].round()}°",
                "Avg Temp",
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                Icons.wb_sunny,
                "${dayData['astro']['sunrise']}",
                "Sunrise",
              ),
              _buildInfoChip(
                Icons.nights_stay,
                "${dayData['astro']['sunset']}",
                "Sunset",
              ),
              _buildInfoChip(
                Icons.grain,
                "${day['daily_chance_of_rain']}%",
                "Rain",
              ),
              _buildInfoChip(
                Icons.thermostat_outlined,
                "Feels ${day['avgtemp_c'].round()}°",
                "UV ${day['uv']}",
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day['condition']['text'],
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(int code, bool isDay) =>
      {
        1000: isDay ? Icons.wb_sunny : Icons.nights_stay,
        1003: isDay ? Icons.wb_cloudy : Icons.cloud,
        1006: Icons.cloud,
        1009: Icons.cloud,
        1030: Icons.foggy,
        1135: Icons.foggy,
        1063: Icons.grain,
        1180: Icons.grain,
        1183: Icons.grain,
        1087: Icons.thunderstorm,
        1273: Icons.thunderstorm,
        1114: Icons.ac_unit,
        1210: Icons.ac_unit,
      }[code] ??
      (isDay ? Icons.wb_sunny : Icons.nights_stay);

  Color _getIconColor(IconData icon) =>
      {
        Icons.wb_sunny: Colors.amber,
        Icons.nights_stay: Colors.indigo[300]!,
        Icons.cloud: Colors.grey[400]!,
        Icons.wb_cloudy: Colors.grey[400]!,
        Icons.thunderstorm: Colors.blue[600]!,
        Icons.grain: Colors.blue[400]!,
        Icons.ac_unit: Colors.lightBlue[200]!,
        Icons.foggy: Colors.grey[300]!,
      }[icon] ??
      Colors.grey[500]!;

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Tomorrow";
    if (difference == -1) return "Yesterday";

    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return dayNames[date.weekday - 1];
  }
}
