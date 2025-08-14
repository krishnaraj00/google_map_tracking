

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Model/data_base/app_db.dart';

class AppleMapWidget extends StatelessWidget {
  final Stream<List<LocationPoint>> pointsStream;

  const AppleMapWidget({super.key, required this.pointsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LocationPoint>>(
      stream: pointsStream,
      builder: (context, snapshot) {
        final points = snapshot.data ?? [];

        return Scaffold(
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade100,
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Apple Maps View',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: points.isEmpty
                    ? const Center(
                  child: Text(
                    'No location data yet.\nStart moving to see your route!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
                    : ListView.builder(
                  itemCount: points.length,
                  itemBuilder: (context, index) {
                    final point = points[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        'Point ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Lat: ${point.latitude.toStringAsFixed(6)}\n'
                            'Lng: ${point.longitude.toStringAsFixed(6)}',
                      ),
                      trailing: Text(
                        '${point.timestamp.hour}:${point.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
