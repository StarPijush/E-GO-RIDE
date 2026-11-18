import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/features/home/presentation/widgets/home_current_location_marker.dart';
import 'package:e_go/features/home/presentation/widgets/home_map_painter.dart';
import 'package:e_go/mock_data/mock_data.dart';

/// Interactive Home map section.
///
/// Implements:
/// - Exact reference map appearance (muted terrain #E8EDE2, green reserves #D3E4C6,
///   white roads, yellow state highway with dashed center, slate railway).
/// - Current-location marker with floating tooltip pill and pulsing beacon wave.
/// - NO floating GPS/recenter button.
/// - NO floating brand logo overlay.
class HomeMapView extends StatefulWidget {
  const HomeMapView({super.key, this.tileProvider});

  /// Injectable for tests so no network tiles are requested.
  final TileProvider? tileProvider;

  @override
  State<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<HomeMapView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AppState>().currentLocation.coordinate;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Reference Stylized Map Painter Background
        const Positioned.fill(
          child: CustomPaint(
            painter: HomeMapStylingPainter(),
          ),
        ),

        // 2. Interactive FlutterMap with TileLayer & MarkerLayer
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            backgroundColor: Colors.transparent,
            initialCenter: current ?? MockData.jhargramCenter,
            initialZoom: 14,
            minZoom: 10,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ego.customer',
              tileProvider: widget.tileProvider,
            ),
            if (current != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: current,
                    width: 180,
                    height: 74,
                    alignment: Alignment.center,
                    child: const HomeCurrentLocationMarker(),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
