import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/offering.dart';
import '../theme/app_theme.dart';
import '../utils/status_extensions.dart';

enum MapBasemap {
  streets('Streets', Icons.map_outlined, 19),
  satellite('Satellite', Icons.satellite_alt, 17),
  hybrid('Hybrid', Icons.layers, 17),
  terrain('Terrain', Icons.terrain, 16);

  const MapBasemap(this.label, this.icon, this.maxNativeZoom);

  final String label;
  final IconData icon;
  final int maxNativeZoom;
}

class OfferingMap extends StatefulWidget {
  final List<Offering> offerings;
  final String? selectedId;
  final ValueChanged<Offering>? onOfferingTap;
  final EdgeInsets padding;

  const OfferingMap({
    super.key,
    required this.offerings,
    this.selectedId,
    this.onOfferingTap,
    this.padding = const EdgeInsets.all(56),
  });

  List<Offering> get locatedOfferings => offerings
      .where((o) => o.latitude != null && o.longitude != null)
      .toList();

  @override
  State<OfferingMap> createState() => _OfferingMapState();
}

class _OfferingMapState extends State<OfferingMap> {
  final MapController _controller = MapController();
  final ValueNotifier<double> _rotation = ValueNotifier(0);
  MapBasemap _basemap = MapBasemap.streets;

  static const double _minZoom = 2;
  static const double _maxZoom = 18;

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  List<Widget> _baseLayers() {
    switch (_basemap) {
      case MapBasemap.satellite:
        return [_tileLayer(_esri('World_Imagery'))];
      case MapBasemap.hybrid:
        return [
          _tileLayer(_esri('World_Imagery')),
          _tileLayer(_esri('Reference/World_Boundaries_and_Places')),
        ];
      case MapBasemap.terrain:
        return [
          _tileLayer('https://tile.opentopomap.org/{z}/{x}/{y}.png'),
        ];
      case MapBasemap.streets:
        return [
          _tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
        ];
    }
  }

  String _esri(String service) =>
      'https://server.arcgisonline.com/ArcGIS/rest/services/$service/MapServer/tile/{z}/{y}/{x}';

  Widget _tileLayer(String urlTemplate) {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: 'com.example.geoterra_monitoring',
      tileDisplay: const TileDisplay.instantaneous(),
      maxNativeZoom: _basemap.maxNativeZoom,
      maxZoom: _maxZoom,
    );
  }

  @override
  void didUpdateWidget(covariant OfferingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.selectedId;
    if (id != null && id != oldWidget.selectedId) {
      final located = widget.locatedOfferings;
      final match = located.where((o) => o.id == id);
      if (match.isNotEmpty) {
        final offering = match.first;
        _controller.move(
          LatLng(offering.latitude!, offering.longitude!),
          14,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final located = widget.locatedOfferings;
    if (located.isEmpty) {
      return const _MapEmptyState();
    }

    final points =
        located.map((o) => LatLng(o.latitude!, o.longitude!)).toList();

    return Stack(
      children: [
        RepaintBoundary(
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCameraFit: points.length > 1
                  ? CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(points),
                      padding: widget.padding,
                    )
                  : CameraFit.coordinates(
                      coordinates: points,
                      padding: widget.padding,
                    ),
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              onPositionChanged: (camera, hasGesture) {
                if ((camera.rotation - _rotation.value).abs() > 0.01) {
                  _rotation.value = camera.rotation;
                }
              },
            ),
            children: [
              ..._baseLayers(),
              MarkerLayer(
                markers: located.map((offering) {
                  final selected = offering.id == widget.selectedId;
                  return Marker(
                    point: LatLng(offering.latitude!, offering.longitude!),
                    width: selected ? 54 : 46,
                    height: selected ? 68 : 58,
                    child: GestureDetector(
                      onTap: () => widget.onOfferingTap?.call(offering),
                      child: MapPin(
                        selected: selected,
                        status: offering.status,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: _legend(),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _controls(),
        ),
      ],
    );
  }

  Widget _legend() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.surface.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'STATUS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            for (final status in OfferingStatus.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _zoomBy(double delta) {
    final camera = _controller.camera;
    final zoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _controller.move(camera.center, zoom);
  }

  void _resetRotation() {
    _controller.rotate(0);
    _rotation.value = 0;
  }

  Widget _controls() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.surface,
      child: Column(
        children: [
          _controlButton(
            icon: Icons.layers_outlined,
            tooltip: 'Basemap',
            onTap: _pickBasemap,
          ),
          const Divider(height: 1, indent: 6, endIndent: 6),
          _controlButton(
            icon: Icons.add,
            tooltip: 'Zoom in',
            onTap: () => _zoomBy(1),
          ),
          const Divider(height: 1, indent: 6, endIndent: 6),
          _controlButton(
            icon: Icons.remove,
            tooltip: 'Zoom out',
            onTap: () => _zoomBy(-1),
          ),
          const Divider(height: 1, indent: 6, endIndent: 6),
          _compassButton(),
        ],
      ),
    );
  }

  Future<void> _pickBasemap() async {
    final selected = await showModalBottomSheet<MapBasemap>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Basemap',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<MapBasemap>(
              groupValue: _basemap,
              onChanged: (value) => Navigator.pop(context, value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final basemap in MapBasemap.values)
                    RadioListTile<MapBasemap>(
                      value: basemap,
                      activeColor: AppColors.primary,
                      title: Text(basemap.label),
                      secondary: Icon(
                        basemap.icon,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null && selected != _basemap) {
      setState(() => _basemap = selected);
    }
  }

  Widget _controlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          width: 42,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _compassButton() {
    return Tooltip(
      message: 'Reset north',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _resetRotation,
        child: SizedBox(
          height: 42,
          width: 42,
          child: Center(
            child: ValueListenableBuilder<double>(
              valueListenable: _rotation,
              builder: (context, rotation, child) {
                return Transform.rotate(
                  angle: -rotation * math.pi / 180,
                  child: child,
                );
              },
              child: Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.4),
                ),
                child: const Icon(
                  Icons.navigation,
                  size: 15,
                  color: AppColors.onHold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MapPin extends StatelessWidget {
  final bool selected;
  final OfferingStatus status;

  const MapPin({super.key, this.selected = false, required this.status});

  IconData get _icon {
    switch (status) {
      case OfferingStatus.draft:
        return Icons.edit_note;
      case OfferingStatus.sent:
        return Icons.send_outlined;
      case OfferingStatus.accepted:
        return Icons.thumb_up_alt_outlined;
      case OfferingStatus.rejected:
        return Icons.close;
      case OfferingStatus.expired:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final size = selected ? 42.0 : 34.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.accent : Colors.white,
              width: selected ? 3 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            _icon,
            size: selected ? 20 : 17,
            color: Colors.white,
          ),
        ),
        Icon(Icons.arrow_drop_down, color: color, size: 18),
      ],
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.map_outlined,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'No pinned locations yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add coordinates to an offering to see it on the map.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
