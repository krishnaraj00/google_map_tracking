import 'package:flutter/material.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../data_base/app_db.dart';
import '../map/google_map.dart';

class LocationHistoryScreen extends StatefulWidget {
  final AppDatabase database;

  const LocationHistoryScreen({super.key, required this.database});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  List<String> routeIds = [];
  Map<String, Map<String, dynamic>> routeSummaries = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteHistory();
  }

  Future<void> _loadRouteHistory() async {
    try {
      final ids = await widget.database.getAllRouteIds();
      final summaries = <String, Map<String, dynamic>>{};

      for (final routeId in ids) {
        final summary = await widget.database.getRouteSummary(routeId);
        if (summary.isNotEmpty) {
          summaries[routeId] = summary;
        }
      }

      if (mounted) {
        setState(() {
          routeIds = ids;
          routeSummaries = summaries;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _clearAllRoutes() async {
    await widget.database.clearAllRoutes();
    await _loadRouteHistory();
  }

  Future<void> _clearRoute(String routeId) async {
    await widget.database.clearRoute(routeId);
    await _loadRouteHistory();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRouteHistory,
            tooltip: 'Refresh',
          ),
          if (routeIds.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllRoutes();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All Routes'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : routeIds.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text('No Tracking History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Start tracking to see your routes.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      )
          : ListView.builder(
        itemCount: routeIds.length,
        itemBuilder: (context, index) {
          final routeId = routeIds[index];
          final summary = routeSummaries[routeId];

          if (summary == null) return const SizedBox.shrink();

          return Card(
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 10),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12.0),
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurpleAccent,
                child: const Icon(Icons.route, color: Colors.white),
              ),
              title: Text('Route ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Started: ${_formatDateTime(summary['startTime'])}'),
                    Text('Duration: ${_formatDuration(summary['duration'])}'),
                    Text('Points: ${summary['pointCount']}'),
                  ],
                ),
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _clearRoute(routeId),
                    tooltip: 'Delete Route',
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteDetailScreen(
                      database: widget.database,
                      routeId: routeId,
                      summary: summary,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class RouteDetailScreen extends StatelessWidget {
  final AppDatabase database;
  final String routeId;
  final Map<String, dynamic> summary;

  const RouteDetailScreen({super.key, required this.database, required this.routeId, required this.summary});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Route Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(thickness: 1.5),
                  _buildSummaryRow('Start Time', _formatDateTime(summary['startTime'])),
                  _buildSummaryRow('End Time', _formatDateTime(summary['endTime'])),
                  _buildSummaryRow('Duration', _formatDuration(summary['duration'])),
                  _buildSummaryRow('Total Points', '${summary['pointCount']}'),
                ],
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMapWidget(pointsStream: database.watchPointsByRoute(routeId)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16)),
        ],
      ),
    );
  }
}
