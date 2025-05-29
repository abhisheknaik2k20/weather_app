import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:my_app/screens/JOURNEY/map_widget.dart';
import 'package:my_app/screens/JOURNEY/model.dart';

class JourneyPredict extends StatefulWidget {
  const JourneyPredict({super.key});

  @override
  State<JourneyPredict> createState() => _JourneyPredictState();
}

class _JourneyPredictState extends State<JourneyPredict> {
  final Model _weatherService = Model();

  LatLng? _fromLocation;
  LatLng? _toLocation;
  String _fromLocationName = '';
  String _toLocationName = '';
  bool _isSelectingFrom = true;
  bool _isLoading = false;
  String _analysisResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journey Weather Predictor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildLocationPanel(),
          Expanded(
            child: _analysisResult.isNotEmpty
                ? _buildMapWithAnalysis()
                : _buildMapOnly(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPanel() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        _buildLocationSelector(
          'From',
          _fromLocation,
          _fromLocationName,
          Colors.green,
          _isSelectingFrom,
          () => setState(() => _isSelectingFrom = true),
        ),
        const SizedBox(height: 12),
        _buildLocationSelector(
          'To',
          _toLocation,
          _toLocationName,
          Colors.red,
          !_isSelectingFrom,
          () => setState(() => _isSelectingFrom = false),
        ),
        const SizedBox(height: 12),
        _buildInstructions(),
      ],
    ),
  );

  Widget _buildLocationSelector(
    String title,
    LatLng? location,
    String locationName,
    Color color,
    bool isActive,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? Colors.blue : Colors.grey.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? Colors.blue.withOpacity(0.05) : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              location != null
                  ? (locationName.isEmpty ? 'Selected Location' : locationName)
                  : 'Tap to select',
              style: TextStyle(
                color: location != null ? Colors.black87 : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (location != null)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    ),
  );

  Widget _buildInstructions() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isSelectingFrom
                ? 'Tap on map to select FROM location'
                : 'Tap on map to select TO location',
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildMapOnly() => Column(
    children: [
      Expanded(child: _buildMap()),
      _buildActionButtons(),
    ],
  );

  Widget _buildMapWithAnalysis() {
    return Column(
      children: [
        Expanded(flex: 2, child: _buildMap()),
        Expanded(flex: 3, child: _buildAnalysisPanel()),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildMap() => MapWidget(
    fromLocation: _fromLocation,
    toLocation: _toLocation,
    onLocationSelected: _onLocationSelected,
    onLocationNameFetched: _onLocationNameFetched,
  );

  Widget _buildAnalysisPanel() => Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Weather Safety Analysis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: Markdown(
            data: _analysisResult,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 14, height: 1.4),
              h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              listBullet: const TextStyle(fontSize: 14),
              code: TextStyle(
                backgroundColor: Colors.grey[100],
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildActionButtons() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canAnalyze ? _analyzeJourney : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? _buildLoadingIndicator()
                : const Text(
                    'Analyze Journey Safety',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _clearSelections,
            child: const Text('Clear Selections'),
          ),
        ),
      ],
    ),
  );

  Widget _buildLoadingIndicator() => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      SizedBox(width: 12),
      Text('Analyzing Weather...'),
    ],
  );

  bool get _canAnalyze =>
      _fromLocation != null && _toLocation != null && !_isLoading;

  void _onLocationSelected(LatLng location, bool isFrom) {
    setState(() {
      if (isFrom) {
        _fromLocation = location;
        _isSelectingFrom = false;
      } else {
        _toLocation = location;
      }
      _analysisResult = '';
    });
  }

  void _onLocationNameFetched(String name, bool isFrom) {
    if (mounted) {
      setState(() {
        if (isFrom) {
          _fromLocationName = name;
        } else {
          _toLocationName = name;
        }
      });
    }
  }

  Future<void> _analyzeJourney() async {
    if (!_canAnalyze) return;

    setState(() {
      _isLoading = true;
      _analysisResult = '';
    });

    try {
      final analysis = await _weatherService.analyzeJourney(
        _fromLocation!,
        _toLocation!,
      );
      setState(() => _analysisResult = analysis);
    } catch (e) {
      setState(
        () => _analysisResult =
            '## ❌ Error\n\nError analyzing journey: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearSelections() {
    setState(() {
      _fromLocation = null;
      _toLocation = null;
      _fromLocationName = '';
      _toLocationName = '';
      _isSelectingFrom = true;
      _analysisResult = '';
    });
  }
}
