import 'package:equatable/equatable.dart';
import '../../../data/models/map_marker_model.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {
  const MapInitial();
}

class MapLoading extends MapState {
  const MapLoading();
}

class MapEmpty extends MapState {
  final String message;
  final MapCenter? center;

  const MapEmpty({
    this.message = 'No smart city features or incidents are currently active on the map.',
    this.center,
  });

  @override
  List<Object?> get props => [message, center];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}

class MapLoaded extends MapState {
  final MapFeaturesData data;
  final String selectedFilter; // 'All', 'Incidents', 'Wastewater', 'Facilities', 'Ambulances'
  final String searchQuery;
  final MapMarker? selectedMarker;
  final MapMarker? activeNavigationMarker;
  final double currentCenterLat;
  final double currentCenterLng;
  final double currentZoom;

  const MapLoaded({
    required this.data,
    this.selectedFilter = 'All',
    this.searchQuery = '',
    this.selectedMarker,
    this.activeNavigationMarker,
    required this.currentCenterLat,
    required this.currentCenterLng,
    required this.currentZoom,
  });

  List<MapMarker> get filteredMarkers {
    return data.allMarkers.where((m) {
      // 1. Issue category & layer filter
      if (selectedFilter != 'All') {
        final f = selectedFilter.toLowerCase();
        if (f == 'road' || f.contains('road')) {
          if (!m.matchesCategory('road') && !m.matchesCategory('pothole')) {
            return false;
          }
        } else if (f == 'wastewater' || f.contains('wastewater')) {
          if (m.type != MapMarkerType.wastewater &&
              !m.matchesCategory('wastewater') &&
              !m.matchesCategory('sewer') &&
              !m.matchesCategory('drain')) {
            return false;
          }
        } else if (f == 'water' || f.contains('water')) {
          if (m.type == MapMarkerType.wastewater) {
            return false;
          }
          if (!m.matchesCategory('water')) {
            return false;
          }
        } else if (f == 'electricity' || f.contains('electric') || f.contains('power')) {
          if (!m.matchesCategory('electric') &&
              !m.matchesCategory('power') &&
              !m.matchesCategory('light')) {
            return false;
          }
        } else if (f == 'sanitation' || f.contains('sanitat') || f.contains('garbage')) {
          if (!m.matchesCategory('sanitat') &&
              !m.matchesCategory('garbage') &&
              !m.matchesCategory('clean')) {
            return false;
          }
        } else if (f == 'healthcare' || f.contains('health') || f.contains('hosp')) {
          if (m.type != MapMarkerType.facility &&
              m.type != MapMarkerType.ambulance &&
              !m.matchesCategory('health') &&
              !m.matchesCategory('hosp') &&
              !m.matchesCategory('clinic') &&
              !m.matchesCategory('medic')) {
            return false;
          }
        } else if (f == 'traffic' || f.contains('traffic')) {
          if (!m.matchesCategory('traffic')) {
            return false;
          }
        } else if (f.contains('facilit')) {
          if (m.type != MapMarkerType.facility) {
            return false;
          }
        } else if (f.contains('ambulance')) {
          if (m.type != MapMarkerType.ambulance) {
            return false;
          }
        } else if (f.contains('incident')) {
          if (m.type != MapMarkerType.incident) {
            return false;
          }
        }
      }

      // 2. Search query filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matches = m.title.toLowerCase().contains(q) ||
            m.locationName.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q) ||
            (m.refNumber != null && m.refNumber!.toLowerCase().contains(q)) ||
            (m.departmentName != null && m.departmentName!.toLowerCase().contains(q)) ||
            (m.pointCode != null && m.pointCode!.toLowerCase().contains(q)) ||
            (m.priority != null && m.priority!.toLowerCase().contains(q)) ||
            (m.status != null && m.status!.toLowerCase().contains(q));
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  MapLoaded copyWith({
    MapFeaturesData? data,
    String? selectedFilter,
    String? searchQuery,
    MapMarker? selectedMarker,
    bool clearSelectedMarker = false,
    MapMarker? activeNavigationMarker,
    bool clearNavigationMarker = false,
    double? currentCenterLat,
    double? currentCenterLng,
    double? currentZoom,
  }) {
    return MapLoaded(
      data: data ?? this.data,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMarker: clearSelectedMarker ? null : (selectedMarker ?? this.selectedMarker),
      activeNavigationMarker: clearNavigationMarker ? null : (activeNavigationMarker ?? this.activeNavigationMarker),
      currentCenterLat: currentCenterLat ?? this.currentCenterLat,
      currentCenterLng: currentCenterLng ?? this.currentCenterLng,
      currentZoom: currentZoom ?? this.currentZoom,
    );
  }

  @override
  List<Object?> get props => [
        data,
        selectedFilter,
        searchQuery,
        selectedMarker,
        activeNavigationMarker,
        currentCenterLat,
        currentCenterLng,
        currentZoom,
      ];
}
