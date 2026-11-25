import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'report_detail_screen.dart';
import 'widgets.dart';

/// Map of all visible reports (OpenStreetMap tiles, no API key needed).
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppProvider>().visible;
    final center = list.isEmpty
        ? const LatLng(30.0444, 31.2357)
        : LatLng(list.first.lat, list.first.lng);
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartcity.smart_city',
        ),
        MarkerLayer(markers: [
          for (final r in list)
            Marker(
              point: LatLng(r.lat, r.lng),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReportDetailScreen(reportId: r.id!))),
                child: Icon(Icons.location_on,
                    size: 44, color: statusColor(r.status)),
              ),
            ),
        ]),
      ],
    );
  }
}
