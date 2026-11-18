import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/map_marker_model.dart';
import '../../../data/repositories/map_repository.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final MapRepository mapRepository;

  MapCubit({required this.mapRepository}) : super(const MapInitial());

  /// Fetches map features and layers from the real API GET /map/features
  Future<void> loadMapFeatures({bool refresh = false}) async {
    if (!refresh && state is MapLoading) return;
    emit(const MapLoading());

    try {
      final data = await mapRepository.getMapFeatures();

      if (data.isEmpty && !data.center.hasPoints) {
        emit(MapEmpty(
          message: 'No smart city incidents or features currently reported.',
          center: data.center,
        ));
        return;
      }

      emit(MapLoaded(
        data: data,
        currentCenterLat: data.center.lat,
        currentCenterLng: data.center.lng,
        currentZoom: data.center.defaultZoom,
      ));
    } catch (e) {
      emit(MapError(
        e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', ''),
      ));
    }
  }

  void setFilter(String filter) {
    if (state is MapLoaded) {
      final s = state as MapLoaded;
      emit(s.copyWith(selectedFilter: filter));
    }
  }

  void search(String query) {
    if (state is MapLoaded) {
      final s = state as MapLoaded;
      emit(s.copyWith(searchQuery: query.trim()));
    }
  }

  void selectMarker(MapMarker? marker) {
    if (state is MapLoaded) {
      final s = state as MapLoaded;
      if (marker == null) {
        emit(s.copyWith(clearSelectedMarker: true));
      } else {
        emit(s.copyWith(
          selectedMarker: marker,
          currentCenterLat: marker.lat,
          currentCenterLng: marker.lng,
        ));
      }
    }
  }

  void setNavigationTarget(MapMarker? marker) {
    if (state is MapLoaded) {
      final s = state as MapLoaded;
      if (marker == null) {
        emit(s.copyWith(clearNavigationMarker: true));
      } else {
        emit(s.copyWith(
          activeNavigationMarker: marker,
          currentCenterLat: marker.lat,
          currentCenterLng: marker.lng,
        ));
      }
    }
  }

  void recenterToInitial() {
    if (state is MapLoaded) {
      final s = state as MapLoaded;
      emit(s.copyWith(
        currentCenterLat: s.data.center.lat,
        currentCenterLng: s.data.center.lng,
        currentZoom: s.data.center.defaultZoom,
      ));
    }
  }
}
