import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../data/models/map_marker_model.dart';
import 'bloc/map_cubit.dart';
import 'bloc/map_state.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedFacility;

  const MapScreen({super.key, this.selectedFacility});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLegendExpanded = false;
  bool _isAcquiringGps = false;

  @override
  void initState() {
    super.initState();
    // Load map features via BLoC architecture on screen load
    context.read<MapCubit>().loadMapFeatures();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFacility != null && widget.selectedFacility != oldWidget.selectedFacility) {
      _applySelectedFacility(widget.selectedFacility!);
    }
  }

  void _applySelectedFacility(Map<String, dynamic> facility) {
    final title = facility['title'] as String? ?? 'Healthcare Facility';
    final location = facility['location'] as String? ?? 'Facility Location';
    final lat = MapMarker.parseCoordinate(facility['lat']);
    final lng = MapMarker.parseCoordinate(facility['lng']);

    if (lat != null && lng != null) {
      final pin = MapMarker(
        id: 'selected_${title.hashCode}',
        title: title,
        description: facility['details'] as String? ?? 'Facility',
        type: MapMarkerType.facility,
        lat: lat,
        lng: lng,
        locationName: location,
        status: 'Operational',
        priority: 'Facility',
      );
      context.read<MapCubit>().setNavigationTarget(pin);
      _mapController.move(LatLng(lat, lng), 16.0);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── GPS Acquisition & Incident Reporting ─────────────────────────────────

  Future<void> _handleReportIncidentWithGps() async {
    setState(() => _isAcquiringGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable GPS / Location services to report with your live coordinates.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
        _navigateToReportScreen(null, null);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied. You can enter the location manually.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _navigateToReportScreen(null, null);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied. You can enter the location manually.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _navigateToReportScreen(null, null);
        return;
      }

      // Capture device high-accuracy GPS coordinates
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 Live GPS coordinates acquired (${position.latitude.toStringAsFixed(4)}°, ${position.longitude.toStringAsFixed(4)}°)',
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      _navigateToReportScreen(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS note: $e. You can specify location manually.')),
        );
      }
      _navigateToReportScreen(null, null);
    } finally {
      if (mounted) {
        setState(() => _isAcquiringGps = false);
      }
    }
  }

  void _navigateToReportScreen(double? lat, double? lng) {
    String? locText;
    if (lat != null && lng != null) {
      locText = 'Live GPS (${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E)';
    }

    context.push(
      '/complaints/new',
      extra: {
        'lat': lat,
        'lng': lng,
        'location': locText,
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: BlocConsumer<MapCubit, MapState>(
        listener: (context, state) {
          if (state is MapLoaded) {
            // Center map on initial API data.center
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mapController.move(
                  LatLng(state.data.center.lat, state.data.center.lng),
                  state.data.center.defaultZoom > 0 ? state.data.center.defaultZoom : 14.0,
                );
              }
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // OpenStreetMap Canvas or State Views
              if (state is MapLoading || state is MapInitial)
                _buildLoadingState()
              else if (state is MapError)
                _buildErrorState(state.message)
              else if (state is MapEmpty)
                _buildEmptyState(state.message, state.center)
              else if (state is MapLoaded)
                _buildOpenStreetMap(state),

              // Top Search Bar & Layer Filters
              _buildTopHeader(state),

              // Filter empty notice
              if (state is MapLoaded && state.filteredMarkers.isEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 146,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No ${state.selectedFilter} issues currently reported.',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.read<MapCubit>().setFilter('All'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Zoom & GPS Recenter Controls (Top Right)
              if (state is MapLoaded)
                _buildMapControls(state),

              // Map Legend Card (Bottom Left)
              if (state is MapLoaded)
                _buildLegendCard(state),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedTap(
          onTap: _isAcquiringGps ? null : _handleReportIncidentWithGps,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAcquiringGps)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '+ Report Incident',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── OpenStreetMap Widget with flutter_map ───────────────────────────────────

  Widget _buildOpenStreetMap(MapLoaded state) {
    final centerLat = state.data.center.lat;
    final centerLng = state.data.center.lng;
    final defaultZoom = state.data.center.defaultZoom > 0 ? state.data.center.defaultZoom : 14.0;

    final filteredMarkers = state.filteredMarkers;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: defaultZoom,
        minZoom: 3.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // OpenStreetMap Standard Tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'in.techsparkventures.smartcityapp',
          maxZoom: 19,
        ),

        // Marker Layer with Real API Markers
        MarkerLayer(
          markers: [
            // Origin / Center Beacon marker
            Marker(
              point: LatLng(centerLat, centerLng),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              child: _buildCenterBeaconWidget(centerLat, centerLng),
            ),

            // Incident and layer markers placed at their real GPS coordinates
            ...filteredMarkers.map((m) {
              final isTarget = state.activeNavigationMarker?.id == m.id || state.selectedMarker?.id == m.id;

              return Marker(
                point: LatLng(m.lat, m.lng),
                width: 48,
                height: 54,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => _onMarkerTap(m),
                  child: _buildMarkerPinWidget(m, isTarget: isTarget),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // ── State Screens ──────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading OpenStreetMap...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fetching live incidents and layers from server',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Map Data',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMedium),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.read<MapCubit>().loadMapFeatures(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry Connection',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, MapCenter? center) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map_outlined, size: 36, color: AppColors.textMedium),
            ),
            const SizedBox(height: 16),
            Text(
              'No Map Features Found',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMedium),
            ),
            if (center != null) ...[
              const SizedBox(height: 8),
              Text(
                'Map Center: ${center.lat.toStringAsFixed(4)}°, ${center.lng.toStringAsFixed(4)}°',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.read<MapCubit>().loadMapFeatures(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Refresh Map',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header, Controls, Legend ───────────────────────────────────────────────

  Widget _buildTopHeader(MapState state) {
    String centerInfo = 'Live OSM';
    List<MapMarker> allMarkers = [];
    String activeFilter = 'All';

    if (state is MapLoaded) {
      centerInfo = '${state.data.center.lat.toStringAsFixed(3)}°, ${state.data.center.lng.toStringAsFixed(3)}°';
      allMarkers = state.data.allMarkers;
      activeFilter = state.selectedFilter;
    } else if (state is MapEmpty && state.center != null) {
      centerInfo = '${state.center!.lat.toStringAsFixed(3)}°, ${state.center!.lng.toStringAsFixed(3)}°';
    }

    int countFor(String key) {
      final k = key.toLowerCase();
      if (k == 'all') return allMarkers.length;
      if (k == 'road') {
        return allMarkers.where((m) => m.matchesCategory('road') || m.matchesCategory('pothole')).length;
      }
      if (k == 'water') {
        return allMarkers.where((m) => m.type != MapMarkerType.wastewater && m.matchesCategory('water')).length;
      }
      if (k == 'sanitation') {
        return allMarkers.where((m) => m.matchesCategory('sanitat') || m.matchesCategory('garbage') || m.matchesCategory('clean')).length;
      }
      if (k == 'electricity') {
        return allMarkers.where((m) => m.matchesCategory('electric') || m.matchesCategory('power') || m.matchesCategory('light')).length;
      }
      if (k == 'healthcare') {
        return allMarkers.where((m) => m.type == MapMarkerType.facility || m.type == MapMarkerType.ambulance || m.matchesCategory('health') || m.matchesCategory('hosp') || m.matchesCategory('clinic') || m.matchesCategory('medic')).length;
      }
      if (k == 'traffic') {
        return allMarkers.where((m) => m.matchesCategory('traffic')).length;
      }
      if (k == 'wastewater') {
        return allMarkers.where((m) => m.type == MapMarkerType.wastewater || m.matchesCategory('wastewater') || m.matchesCategory('sewer') || m.matchesCategory('drain')).length;
      }
      return 0;
    }

    final filterItems = <({String key, String label, String icon})>[
      (key: 'All', label: 'All Issues', icon: '📍'),
      (key: 'Road', label: 'Road', icon: '🚧'),
      (key: 'Water', label: 'Water', icon: '💧'),
      (key: 'Sanitation', label: 'Sanitation', icon: '🧹'),
      (key: 'Electricity', label: 'Electricity', icon: '⚡'),
      (key: 'Healthcare', label: 'Healthcare', icon: '🏥'),
      (key: 'Traffic', label: 'Traffic', icon: '🚦'),
      (key: 'Wastewater', label: 'Wastewater', icon: '🌊'),
    ];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.map_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Smart City Map',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  // Dynamic center coordinates pill from data.center
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location_rounded, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          centerInfo,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => context.read<MapCubit>().search(v),
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'Search incidents, pumping stations, facilities...',
                          hintStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textLight),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          context.read<MapCubit>().search('');
                        },
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textLight),
                      ),
                  ],
                ),
              ),
            ),

            // Route active banner
            if (state is MapLoaded && state.activeNavigationMarker != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_rounded, color: Color(0xFF0F766E), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Focused on: ${state.activeNavigationMarker!.title} • ${state.activeNavigationMarker!.locationName}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F766E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.read<MapCubit>().setNavigationTarget(null),
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Issue Category Filter Chips
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
                itemCount: filterItems.length,
                itemBuilder: (context, index) {
                  final item = filterItems[index];
                  final isSelected = activeFilter.toLowerCase() == item.key.toLowerCase();
                  final count = countFor(item.key);

                  return AnimatedTap(
                    onTap: () {
                      context.read<MapCubit>().setFilter(item.key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            '${item.label} ($count)',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(MapLoaded state) {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 165,
      child: Column(
        children: [
          // GPS Recenter Button (Centers to data.center)
          AnimatedTap(
            onTap: () {
              _mapController.move(
                LatLng(state.data.center.lat, state.data.center.lng),
                state.data.center.defaultZoom > 0 ? state.data.center.defaultZoom : 14.0,
              );
              context.read<MapCubit>().recenterToInitial();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '📍 Re-centered to Map Center (${state.data.center.lat.toStringAsFixed(4)}°, ${state.data.center.lng.toStringAsFixed(4)}°)',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(height: 10),

          // Zoom Controls (+ / -)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    final cur = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, cur + 1.0);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Icons.add, size: 20, color: AppColors.textDark),
                  ),
                ),
                Container(width: 24, height: 1, color: AppColors.border),
                InkWell(
                  onTap: () {
                    final cur = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, cur - 1.0);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Icons.remove, size: 20, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Refresh Button
          AnimatedTap(
            onTap: () => context.read<MapCubit>().loadMapFeatures(refresh: true),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.refresh_rounded, color: AppColors.secondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard(MapLoaded state) {
    final filtered = state.filteredMarkers;
    final incidents = filtered.where((m) => m.type == MapMarkerType.incident).length;
    final wastewater = filtered.where((m) => m.type == MapMarkerType.wastewater).length;
    final facilities = filtered.where((m) => m.type == MapMarkerType.facility).length;
    final ambulances = filtered.where((m) => m.type == MapMarkerType.ambulance).length;

    return Positioned(
      left: 16,
      bottom: 24,
      child: AnimatedTap(
        onTap: () => setState(() => _isLegendExpanded = !_isLegendExpanded),
        child: Container(
          width: 190,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Active Layers (${filtered.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isLegendExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textMedium,
                  ),
                ],
              ),
              if (_isLegendExpanded) ...[
                const SizedBox(height: 8),
                _legendRow(const Color(0xFFE11D48), 'Incidents ($incidents)', Icons.report_problem_rounded),
                if (wastewater > 0)
                  _legendRow(const Color(0xFF0284C7), 'Wastewater ($wastewater)', Icons.water_drop_rounded),
                if (facilities > 0 || state.data.facilities.isNotEmpty)
                  _legendRow(const Color(0xFF0F766E), 'Facilities ($facilities)', Icons.local_hospital_rounded),
                if (ambulances > 0 || state.data.ambulances.isNotEmpty)
                  _legendRow(const Color(0xFFDC2626), 'Ambulances ($ambulances)', Icons.emergency_rounded),
                const SizedBox(height: 4),
                _legendRow(const Color(0xFF2563EB), 'Map Center Beacon', Icons.my_location_rounded),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 11),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMedium, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Marker Pin Widgets & Detail Bottom Sheets ─────────────────────────────

  Widget _buildCenterBeaconWidget(double lat, double lng) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2563EB),
            ),
            child: const Icon(Icons.my_location_rounded, size: 9, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerPinWidget(MapMarker marker, {bool isTarget = false}) {
    final (Color pinColor, IconData pinIcon) = _getMarkerStyle(marker);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing Pulse Ring
        Container(
          width: isTarget ? 48 : 40,
          height: isTarget ? 48 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pinColor.withValues(alpha: isTarget ? 0.35 : 0.22),
            border: Border.all(color: Colors.white, width: isTarget ? 2.5 : 2),
            boxShadow: [
              BoxShadow(
                color: pinColor.withValues(alpha: isTarget ? 0.6 : 0.35),
                blurRadius: isTarget ? 14 : 8,
                spreadRadius: isTarget ? 3 : 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: isTarget ? 32 : 26,
              height: isTarget ? 32 : 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pinColor,
              ),
              child: Icon(pinIcon, color: Colors.white, size: isTarget ? 18 : 14),
            ),
          ),
        ),
        // Small pin pointer
        CustomPaint(
          size: const Size(10, 6),
          painter: _PinTrianglePainter(color: pinColor),
        ),
      ],
    );
  }

  (Color, IconData) _getMarkerStyle(MapMarker m) {
    switch (m.type) {
      case MapMarkerType.incident:
        final cat = (m.category ?? '').toLowerCase();
        final pri = (m.priority ?? '').toLowerCase();
        if (pri == 'critical' || pri == 'high') return (const Color(0xFFDC2626), Icons.report_problem_rounded);
        if (cat.contains('road') || cat.contains('pothole')) return (const Color(0xFFD97706), Icons.construction_rounded);
        if (cat.contains('electric') || cat.contains('power') || cat.contains('light')) return (const Color(0xFFF59E0B), Icons.electric_bolt_rounded);
        if (cat.contains('waste') || cat.contains('drain') || cat.contains('sewer')) return (const Color(0xFF0F766E), Icons.water_damage_rounded);
        if (cat.contains('water')) return (const Color(0xFF0284C7), Icons.water_drop_rounded);
        if (cat.contains('sanitation') || cat.contains('garbage') || cat.contains('clean')) return (const Color(0xFF16A34A), Icons.delete_outline_rounded);
        if (cat.contains('health') || cat.contains('hosp') || cat.contains('medic') || cat.contains('clinic')) return (const Color(0xFF0D9488), Icons.local_hospital_rounded);
        if (cat.contains('traffic')) return (const Color(0xFF2563EB), Icons.traffic_rounded);
        return (const Color(0xFFE11D48), Icons.warning_amber_rounded);

      case MapMarkerType.wastewater:
        return (const Color(0xFF0284C7), Icons.water_drop_rounded);

      case MapMarkerType.facility:
        return (const Color(0xFF0F766E), Icons.local_hospital_rounded);

      case MapMarkerType.ambulance:
        return (const Color(0xFFDC2626), Icons.emergency_rounded);
    }
  }

  void _onMarkerTap(MapMarker marker) {
    context.read<MapCubit>().selectMarker(marker);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildMarkerDetailsSheet(marker),
    );
  }

  Widget _buildMarkerDetailsSheet(MapMarker marker) {
    final (Color markerColor, IconData markerIcon) = _getMarkerStyle(marker);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: AppDimensions.screenPadding,
        right: AppDimensions.screenPadding,
        bottom: MediaQuery.of(context).padding.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Icon + Category Badge + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: markerColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(markerIcon, color: markerColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: markerColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            marker.typeLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: markerColor,
                            ),
                          ),
                        ),
                        if (marker.category != null && marker.category!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              marker.category!.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        if (marker.refNumber != null && marker.refNumber!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              marker.refNumber!,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        if (marker.pointCode != null && marker.pointCode!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              marker.pointCode!,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0284C7),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      marker.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Location Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMedium),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  marker.locationName.isNotEmpty
                      ? marker.locationName
                      : 'Coordinates: ${marker.lat.toStringAsFixed(4)}° N, ${marker.lng.toStringAsFixed(4)}° E',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Detailed properties grid based on type
          if (marker.type == MapMarkerType.incident)
            _buildIncidentDetails(marker)
          else if (marker.type == MapMarkerType.wastewater)
            _buildWastewaterDetails(marker)
          else
            _buildGenericDetails(marker),

          const SizedBox(height: 18),

          // Actions
          Row(
            children: [
              Expanded(
                child: AnimatedTap(
                  onTap: () {
                    Navigator.pop(context);
                    context.read<MapCubit>().setNavigationTarget(marker);
                    _mapController.move(LatLng(marker.lat, marker.lng), 16.5);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📍 Map focused on ${marker.title}'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Focus on Map',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedTap(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentDetails(MapMarker m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _detailChip('Priority', m.priority ?? 'Normal', _priorityColor(m.priority)),
              _detailChip('Status', m.status ?? 'Reported', _statusColor(m.status)),
              if (m.category != null && m.category!.isNotEmpty)
                _detailChip('Category', m.category!, AppColors.primary),
            ],
          ),
          if (m.departmentName != null && m.departmentName!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.business_rounded, size: 15, color: AppColors.textMedium),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Assigned: ${m.departmentName}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (m.description.isNotEmpty && m.description != m.title) ...[
            const SizedBox(height: 8),
            Text(
              m.description,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWastewaterDetails(MapMarker m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _detailChip('Risk Level', m.riskLevel ?? 'Normal', _priorityColor(m.riskLevel)),
              _detailChip('Status', m.lastStatusLevel ?? m.status ?? 'Active', _statusColor(m.lastStatusLevel)),
            ],
          ),
          const SizedBox(height: 8),
          if (m.lastWaterLevel != null && m.lastWaterLevel!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.water_rounded, size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Last Water Level: ${m.lastWaterLevel} meters',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ),
          if (m.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Facility Type: ${m.description}',
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenericDetails(MapMarker m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _detailChip('Type', m.typeLabel, AppColors.secondary),
              if (m.status != null && m.status!.isNotEmpty)
                _detailChip('Status', m.status!, AppColors.success),
            ],
          ),
          if (m.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(m.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark)),
          ],
        ],
      ),
    );
  }

  Widget _detailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _priorityColor(String? priority) {
    final p = (priority ?? '').toLowerCase();
    if (p.contains('crit') || p.contains('urg')) return const Color(0xFFDC2626);
    if (p.contains('high')) return const Color(0xFFEA580C);
    if (p.contains('med')) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }

  Color _statusColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('crit') || s.contains('fail')) return const Color(0xFFDC2626);
    if (s.contains('prog') || s.contains('warn')) return const Color(0xFFD97706);
    if (s.contains('resolv') || s.contains('norm') || s.contains('oper')) return const Color(0xFF16A34A);
    return const Color(0xFF0F766E);
  }
}

class _PinTrianglePainter extends CustomPainter {
  final Color color;

  _PinTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTrianglePainter oldDelegate) => oldDelegate.color != color;
}
