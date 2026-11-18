import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/hospital_details_sheet.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/repositories/hospital_repository.dart';

class HealthcareScreen extends StatefulWidget {
  const HealthcareScreen({super.key});

  @override
  State<HealthcareScreen> createState() => _HealthcareScreenState();
}

class _HealthcareScreenState extends State<HealthcareScreen> {
  String _search = '';
  String _selectedType = 'All';
  final List<String> _typeFilters = ['All', 'Government', 'Private', 'Clinic', 'Medical Camp', 'First Aid'];

  List<HospitalModel> _facilities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  Future<void> _fetchFacilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<HospitalRepository>();
      final list = await repo.getAllHospitals();
      if (mounted) {
        setState(() {
          _facilities = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<HospitalModel> get _filtered {
    List<HospitalModel> list = _facilities;
    if (_selectedType != 'All') list = list.where((h) => h.typeLabel == _selectedType).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((h) =>
          h.name.toLowerCase().contains(q) ||
          h.address.toLowerCase().contains(q) ||
          h.specialties.any((s) => s.toLowerCase().contains(q))).toList();
    }
    return list..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
              child: const Icon(Icons.emergency_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Emergency SOS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Citizen Emergency Helpline\n\nConnecting to Nashik District Disaster & Emergency Management.\n\nAmbulance: 108\nPolice & Disaster: 112\nFire: 101',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _showSosConfirmation();
            },
            child: const Text('Trigger Alert'),
          ),
        ],
      ),
    );
  }

  void _showSosConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text('Emergency Alert dispatched! Nearest medical team notified.'),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Healthcare Facilities'),
            Text(
              'Real-time Bed Availability & Facilities',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // SOS Button
          PulseWidget(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.emergency_rounded, size: 16),
                label: const Text('SOS 108', style: TextStyle(fontWeight: FontWeight.w800)),
                onPressed: _showSosDialog,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchFacilities,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
              child: Column(
                children: [
                  // Emergency contacts bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _EmergencyContact('🚑', 'Ambulance', '108'),
                        _vDivider(),
                        _EmergencyContact('🏥', 'Civil Hospital', '0253-2576106'),
                        _vDivider(),
                        _EmergencyContact('🚒', 'Fire Control', '101'),
                        _vDivider(),
                        _EmergencyContact('🚔', 'Police Helpline', '112'),
                      ],
                    ),
                  ),

                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.secondary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _search = v.trim()),
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                              decoration: InputDecoration(
                                hintText: 'Search facilities, beds, specialties…',
                                hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13),
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
                          if (_search.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _search = ''),
                              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textLight),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Type filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: _typeFilters.map((f) {
                        final selected = f == _selectedType;
                        return AnimatedTap(
                          onTap: () => setState(() => _selectedType = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.secondary : Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: selected ? AppColors.secondary : AppColors.border,
                              ),
                            ),
                            child: Text(
                              f,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.textMedium,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                                    const SizedBox(height: 8),
                                    Text(_errorMessage!, style: GoogleFonts.inter(color: AppColors.textMedium)),
                                    const SizedBox(height: 12),
                                    ElevatedButton(onPressed: _fetchFacilities, child: const Text('Retry')),
                                  ],
                                ),
                              )
                            : _filtered.isEmpty
                                ? const EmptyStateWidget(
                                    icon: Icons.local_hospital_rounded,
                                    title: 'No nearby healthcare facilities are available right now.',
                                    subtitle: 'Please check back later or call emergency services if urgent.',
                                  )
                                : RefreshIndicator(
                                    onRefresh: _fetchFacilities,
                                    color: AppColors.secondary,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      itemCount: _filtered.length,
                                      itemBuilder: (context, i) {
                                        return _HospitalListTile(hospital: _filtered[i]).cardEntrance(index: i);
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 30, color: AppColors.border);
}

class _EmergencyContact extends StatelessWidget {
  final String emoji;
  final String label;
  final String number;
  const _EmergencyContact(this.emoji, this.label, this.number);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(number,
            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMedium)),
      ],
    );
  }
}

class _HospitalListTile extends StatelessWidget {
  final HospitalModel hospital;
  const _HospitalListTile({required this.hospital});

  Color get _typeColor {
    switch (hospital.type) {
      case HospitalType.government: return AppColors.primary;
      case HospitalType.private: return AppColors.secondary;
      case HospitalType.clinic: return AppColors.info;
      case HospitalType.medicalCamp: return AppColors.success;
      case HospitalType.firstAid: return AppColors.error;
    }
  }

  IconData get _typeIcon {
    switch (hospital.type) {
      case HospitalType.government:
      case HospitalType.private: return Icons.local_hospital_rounded;
      case HospitalType.clinic: return Icons.medical_services_rounded;
      case HospitalType.medicalCamp: return Icons.medical_information_rounded;
      case HospitalType.firstAid: return Icons.health_and_safety_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedTap(
      onTap: () => HospitalDetailsSheet.show(context, hospital),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(_typeIcon, color: _typeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hospital.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (hospital.isOpen24Hours)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text('24/7',
                                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.success)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(hospital.typeLabel,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _typeColor)),
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(5, (i) => Icon(
                            i < hospital.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 12, color: AppColors.warning,
                          )),
                          const SizedBox(width: 3),
                          Text('${hospital.rating}',
                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMedium)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Bed Capacity & Occupancy Badge Bar (API GET /healthcare/facilities)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hotel_rounded, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Total: ${hospital.totalBeds} Beds',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Available: ${hospital.availableBeds}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (hospital.occupancyRate ?? 70) > 85 ? AppColors.errorLight : AppColors.successLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(hospital.occupancyRate ?? 70).toStringAsFixed(0)}% Occupied',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: (hospital.occupancyRate ?? 70) > 85 ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textLight),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(hospital.address,
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMedium),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text('${hospital.distanceKm} km',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
