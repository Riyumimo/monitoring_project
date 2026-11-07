part of '../../project_detail_screen.dart';

extension _ProjectMapSections on _ProjectDetailScreenState {
  Widget _mapCard(Project project) {
    final hasLocation = project.latitude != null && project.longitude != null;
    final point = hasLocation
        ? LatLng(project.latitude!, project.longitude!)
        : null;

    return _card(
      key: _mapKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Main Site')),
              _locationBadge(hasLocation),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: point == null
                  ? const _MapPlaceholder()
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: point,
                              initialZoom: 14,
                              minZoom: 3,
                              maxZoom: 18,
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.geoterra_monitoring',
                                maxZoom: 19,
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: point,
                                    width: 54,
                                    height: 54,
                                    child: Icon(
                                      Icons.location_on,
                                      size: 46,
                                      color: AppColors.onHold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.22,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Column(
                            children: [
                              _mapControlButton(
                                icon: Icons.add,
                                tooltip: 'Zoom in',
                                onTap: () => _zoomMap(1),
                              ),
                              const SizedBox(height: 6),
                              _mapControlButton(
                                icon: Icons.remove,
                                tooltip: 'Zoom out',
                                onTap: () => _zoomMap(-1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _zoomMap(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + delta).clamp(3.0, 18.0));
  }

  Widget _mapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _locationBadge(bool hasLocation) {
    final color = hasLocation ? AppColors.completed : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            hasLocation ? 'Verified Location' : 'No Coordinates',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
