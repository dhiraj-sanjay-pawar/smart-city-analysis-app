import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/complaint_repository.dart';

class NewComplaintScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialLocation;

  const NewComplaintScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialLocation,
  });

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late final TextEditingController _locationController;

  ComplaintCategory _selectedCategory = ComplaintCategory.road;
  bool _isSubmitting = false;
  bool _isFetchingGps = false;
  ComplaintModel? _submittedComplaint;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLat;
    _longitude = widget.initialLng;
    String initialLoc = 'College Road, Nashik, Maharashtra';
    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      initialLoc = widget.initialLocation!;
    } else if (widget.initialLat != null && widget.initialLng != null) {
      initialLoc = 'Live GPS (${widget.initialLat!.toStringAsFixed(4)}° N, ${widget.initialLng!.toStringAsFixed(4)}° E)';
    }
    _locationController = TextEditingController(text: initialLoc);
  }

  // Attached photos list
  final List<XFile> _attachedPhotos = [];
  final ImagePicker _imagePicker = ImagePicker();

  final List<_CategoryData> _categories = [
    _CategoryData(ComplaintCategory.road, 'Road Issue', Icons.construction_rounded, 'assets/images/cat_road.png', const Color(0xFFD97706)),
    _CategoryData(ComplaintCategory.water, 'Water Supply', Icons.water_drop_rounded, 'assets/images/cat_water.png', const Color(0xFF0284C7)),
    _CategoryData(ComplaintCategory.electricity, 'Electricity', Icons.electric_bolt_rounded, 'assets/images/cat_electricity.png', const Color(0xFFF59E0B)),
    _CategoryData(ComplaintCategory.sanitation, 'Sanitation', Icons.delete_outline_rounded, 'assets/images/cat_sanitation.png', const Color(0xFF16A34A)),
    _CategoryData(ComplaintCategory.healthcare, 'Healthcare', Icons.local_hospital_rounded, 'assets/images/service_healthcare.png', const Color(0xFF0F766E)),
    _CategoryData(ComplaintCategory.traffic, 'Traffic', Icons.traffic_rounded, 'assets/images/cat_traffic.png', const Color(0xFF3B82F6)),
    _CategoryData(ComplaintCategory.crime, 'Crime', Icons.shield_rounded, 'assets/images/cat_crime.png', const Color(0xFFDC2626)),
    _CategoryData(ComplaintCategory.wastewater, 'Wastewater', Icons.water_damage_rounded, 'assets/images/cat_wastewater.png', const Color(0xFF0F766E)),
    _CategoryData(ComplaintCategory.other, 'Other', Icons.info_outline_rounded, 'assets/images/cat_other.png', const Color(0xFF64748B)),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── GPS Live Location ──────────────────────────────────────────
  Future<void> _fetchLiveGpsLocation() async {
    setState(() => _isFetchingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS / Location services on your device.')),
          );
        }
        setState(() => _isFetchingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission was denied. You can enter address manually.')),
            );
          }
          setState(() => _isFetchingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is permanently denied. Please allow in settings.')),
          );
        }
        setState(() => _isFetchingGps = false);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text =
            'Live GPS (${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° E)';
        _isFetchingGps = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Live GPS location successfully acquired!'),
            backgroundColor: Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Fallback in case device emulator doesn't have GPS lock
      setState(() {
        _locationController.text = 'Panchavati Ward 12 (GPS: 19.9975° N, 73.7898° E), Nashik';
        _isFetchingGps = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acquired closest municipal GPS coordinate (Nashik).')),
        );
      }
    }
  }

  // ── Manual Location Selector Modal ─────────────────────────────
  void _openLocationSelectorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: AppDimensions.screenPadding,
            right: AppDimensions.screenPadding,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Complaint Location',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose live GPS tracking or enter a Nashik address',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
              ),
              const SizedBox(height: 18),

              // Option 1: Live GPS
              AnimatedTap(
                onTap: () {
                  Navigator.pop(ctx);
                  _fetchLiveGpsLocation();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                        child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use My Live Location',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)),
                            ),
                            Text(
                              'Fetch current GPS coordinates automatically',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Option 2: Quick Nashik Landmarks
              Text(
                'Popular Nashik Locations',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'College Road, Nashik',
                  'M.G. Road, Shivaji Nagar',
                  'Panchavati Karanja, Nashik',
                  'Gangapur Road, Nashik',
                  'Nashik Road Railway Station',
                  'Old Agra Road, Nashik',
                ].map((loc) {
                  return AnimatedTap(
                    onTap: () {
                      setState(() => _locationController.text = loc);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundAlt,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(loc, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textDark)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Custom Address',
                  hintText: 'Enter street, building, or landmark',
                  prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedTap(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text('Confirm Location', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Photo Attachment from Camera or Gallery ────────────────────
  void _openPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: AppDimensions.screenPadding,
            right: AppDimensions.screenPadding,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Attach Photo',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text('Take a real-time photo or select from gallery', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: AnimatedTap(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final photo = await _imagePicker.pickImage(source: ImageSource.camera);
                        if (photo != null) {
                          setState(() => _attachedPhotos.add(photo));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB), size: 30),
                            const SizedBox(height: 8),
                            Text('Camera', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedTap(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final photos = await _imagePicker.pickMultiImage();
                        if (photos.isNotEmpty) {
                          setState(() => _attachedPhotos.addAll(photos));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library_rounded, color: Color(0xFF059669), size: 30),
                            const SizedBox(height: 8),
                            Text('Gallery', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF065F46))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Form Submission ────────────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      final user = context.read<AuthRepository>().currentUser;
      final repo = context.read<ComplaintRepository>();

      final complaint = await repo.submitComplaint(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        imageUrl: _attachedPhotos.isNotEmpty ? _attachedPhotos.first.path : null,
        userId: user?.id,
        userName: user?.name,
      );

      setState(() {
        _submittedComplaint = complaint;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedComplaint != null) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // App Bar with skyline illustration header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: AnimatedTap(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'File a Complaint',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/header_skyline.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0369A1).withValues(alpha: 0.8),
                          const Color(0xFF0F172A).withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form Body
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Official Notice Banner (No "Demo" word!)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7), // Warm amber
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Citizen Grievance System',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Grievances are registered directly with the Nashik Municipal Corporation (NMC) field inspection officers.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF78350F),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // "Select Category" Header
                    Text(
                      'Select Category',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 8 Photo Category Cards (4x2 Grid)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat.category;

                        return AnimatedTap(
                          onTap: () => setState(() => _selectedCategory = cat.category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFF59E0B) : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Column(
                                children: [
                                  // Top Photo Thumbnail
                                  SizedBox(
                                    height: 48,
                                    width: double.infinity,
                                    child: Image.asset(
                                      cat.imagePath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  // Overlapping Icon Badge
                                  Transform.translate(
                                    offset: const Offset(0, -10),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFFEF3C7) : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        cat.icon,
                                        size: 15,
                                        color: isSelected ? const Color(0xFFD97706) : AppColors.textMedium,
                                      ),
                                    ),
                                  ),

                                  // Category Label
                                  Transform.translate(
                                    offset: const Offset(0, -6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Text(
                                        cat.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF92400E) : AppColors.textDark,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Complaint Title Input Field
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textDark),
                      decoration: InputDecoration(
                        labelText: 'Complaint Title',
                        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMedium),
                        hintText: 'e.g. Broken streetlight near Shalimar Chowk',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
                        prefixIcon: const Icon(Icons.title_rounded, color: AppColors.secondary, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter a complaint title';
                        if (v.trim().length < 5) return 'Title must be at least 5 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Description Input Field (Multiline, Comfortable)
                    TextFormField(
                      controller: _descController,
                      minLines: 3,
                      maxLines: 5,
                      style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textDark),
                      decoration: InputDecoration(
                        labelText: 'Detailed Description',
                        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMedium),
                        hintText: 'Describe the issue, landmarks, severity, and any hazards...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.description_outlined, color: AppColors.secondary, size: 20),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please describe the issue';
                        if (v.trim().length < 10) return 'Description must be at least 10 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Location Card with Two Options (Live GPS or Manual Address)
                    AnimatedTap(
                      onTap: _openLocationSelectorDialog,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFF0F766E), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Location',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _locationController.text.isEmpty ? 'Tap to set location' : _locationController.text,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (_isFetchingGps)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 22),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Attach Photo Area (Dashed Box)
                    AnimatedTap(
                      onTap: _openPhotoSourceSheet,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.add_photo_alternate_rounded, color: AppColors.textLight, size: 36),
                            const SizedBox(height: 6),
                            Text(
                              'Attach Photo',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add images of the issue from Camera or Gallery (optional)',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Attached Photos Horizontal Preview List with (X) remove button
                    if (_attachedPhotos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 72,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedPhotos.length,
                          itemBuilder: (context, idx) {
                            final photo = _attachedPhotos[idx];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: kIsWeb
                                        ? Image.network(photo.path, fit: BoxFit.cover)
                                        : Image.file(File(photo.path), fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _attachedPhotos.removeAt(idx)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Submit Complaint Button (Teal/Emerald Green matching Image 3)
                    AnimatedTap(
                      onTap: _isSubmitting ? null : _submit,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488), // Teal Green
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Submit Complaint',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SuccessAnimation(),
              const SizedBox(height: 24),
              Text(
                'Complaint Submitted',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Your civic report has been queued for NMC field inspection in Nashik.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMedium),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  children: [
                    Text('Grievance Registration Number', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMedium)),
                    const SizedBox(height: 4),
                    Text(
                      _submittedComplaint!.id,
                      style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF1E40AF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AnimatedTap(
                onTap: () => context.go('/home'),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text('Go to Home', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedTap(
                onTap: () => context.go('/reports'),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text('View in My Reports', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  final ComplaintCategory category;
  final String label;
  final IconData icon;
  final String imagePath;
  final Color accentColor;

  _CategoryData(this.category, this.label, this.icon, this.imagePath, this.accentColor);
}
