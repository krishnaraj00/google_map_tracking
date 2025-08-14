import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../Model/data_base/app_db.dart';



class GoogleMapWidget extends StatelessWidget {
  final Stream<List<LocationPoint>> pointsStream;
  const GoogleMapWidget({super.key, required this.pointsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LocationPoint>>(
      stream: pointsStream,
      builder: (context, snapshot) {
        final points = snapshot.data ?? [];
        final latLngs = points
            .map((e) => LatLng(e.latitude, e.longitude))
            .toList();
        return GoogleMap(
          initialCameraPosition: latLngs.isNotEmpty
              ? CameraPosition(target: latLngs.last, zoom: 16)
              : const CameraPosition(
            target: LatLng(10.7149119, 76.4436529),
            zoom: 14,
          ),
          markers: latLngs.isNotEmpty
              ? {
            Marker(
              markerId: const MarkerId('current'),
              position: latLngs.last,
            ),
          }
              : {},
          polylines: latLngs.length > 1
              ? {
            Polyline(
              polylineId: const PolylineId('route'),
              points: latLngs,
              color: Colors.blue,
              width: 5,
            ),
          }
              : {},
        );
      },
    );
  }
}
//google_map_widget.dart