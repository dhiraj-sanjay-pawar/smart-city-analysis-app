import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/wastewater_model.dart';
import '../../../data/repositories/wastewater_repository.dart';

class WastewaterScreen extends StatefulWidget {
  const WastewaterScreen({super.key});

  @override
  State<WastewaterScreen> createState() => _WastewaterScreenState();
}

class _WastewaterScreenState extends State<WastewaterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = WastewaterRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wastewater & Water Levels'),
            Text(
              'River Godavari Levels & Drainage Observations',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryLight,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Recorded Observations'),
            Tab(text: 'Report Issue'),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ObservationsTab(repo: _repo),
                  _ReportTab(repo: _repo, onSubmitted: () => _tabController.animateTo(0)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ObservationsTab extends StatefulWidget {
  final WastewaterRepository repo;
  const _ObservationsTab({required this.repo});

  @override
  State<_ObservationsTab> createState() => _ObservationsTabState();
}

class _ObservationsTabState extends State<_ObservationsTab> {
  List<WastewaterIssue> _issues = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchObservations();
  }

  Future<void> _fetchObservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await widget.repo.getIssues();
      if (mounted) {
        setState(() {
          _issues = list;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: GoogleFonts.inter(color: AppColors.textMedium)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchObservations, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchObservations,
      color: AppColors.secondary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basin Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF16324F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Godavari Basin Observation Network',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Active ultrasonic water-level telemetry sensors stationed across Ramkund, Tapovan, Gangapur Dam, and Panchavati ghats for Kumbh Mela safety.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Telemetry Stations & Observations (${_issues.length})',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),

          const SizedBox(height: 10),

          ..._issues.asMap().entries.map((entry) {
            final i = entry.key;
            final issue = entry.value;
            final double currentLevel = issue.waterLevelMeters ?? 2.8;
            final double threshold = issue.thresholdMeters ?? 4.0;
            final bool isWarning = currentLevel >= (threshold * 0.75);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: isWarning ? AppColors.warning.withValues(alpha: 0.4) : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          issue.typeLabel,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        issue.id,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textLight),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isWarning ? AppColors.warningLight : AppColors.successLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          isWarning ? 'Advisory Level' : 'Normal',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isWarning ? AppColors.warning : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    issue.description,
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  // Water level gauge bar
                  Row(
                    children: [
                      Text(
                        'Level: ${currentLevel.toStringAsFixed(1)} m',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (currentLevel / threshold).clamp(0.0, 1.0),
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isWarning ? AppColors.warning : AppColors.secondary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Limit: ${threshold.toStringAsFixed(1)} m',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        issue.location,
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ],
              ),
            ).cardEntrance(index: i);
          }),
        ],
      ),
    );
  }
}

class _ReportTab extends StatefulWidget {
  final WastewaterRepository repo;
  final VoidCallback onSubmitted;
  const _ReportTab({required this.repo, required this.onSubmitted});

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _locationController = TextEditingController(text: 'Ramkund Ghat, Panchavati, Nashik');
  WastewaterIssueType _type = WastewaterIssueType.waterlogging;
  bool _isSubmitting = false;
  bool _showSuccess = false;
  String? _submittedId;

  final _types = [
    (WastewaterIssueType.waterlogging, 'Waterlogging', Icons.water_rounded, AppColors.secondary),
    (WastewaterIssueType.drainageBlockage, 'Drain Blockage', Icons.plumbing_rounded, AppColors.warning),
    (WastewaterIssueType.sewageOverflow, 'Sewage Overflow', Icons.water_damage_rounded, AppColors.error),
    (WastewaterIssueType.other, 'Telemetry Watch', Icons.sensors_rounded, AppColors.primary),
  ];

  @override
  void dispose() {
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final issue = await widget.repo.submitIssue(
        type: _type,
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
      );
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
        _submittedId = issue.id;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _showSuccess = false);
        widget.onSubmitted();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuccessAnimation(),
            const SizedBox(height: 16),
            Text('Observation Logged Successfully!',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text('Report ID: ${_submittedId ?? ""}',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.secondary)),
            const SizedBox(height: 4),
            Text('Registered for municipal drainage maintenance',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium)),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          Text(
            'Select Observation Type',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
            children: _types.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final isSelected = _type == t.$1;
              return AnimatedTap(
                onTap: () => setState(() => _type = t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? t.$4.withValues(alpha: 0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: isSelected ? t.$4 : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.$3, color: t.$4, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          t.$2,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? t.$4 : AppColors.textMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
            }).toList(),
          ),

          const SizedBox(height: 16),

          AppTextField(
            label: 'Description',
            hint: 'Describe water level observation or blockage…',
            controller: _descController,
            maxLines: 4,
            maxLength: 300,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter a description';
              return null;
            },
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Location / Sensor Point',
            controller: _locationController,
            prefixIcon: Icons.location_on_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter location';
              return null;
            },
          ),
          const SizedBox(height: 24),

          AppButton(
            label: 'Submit Observation',
            isLoading: _isSubmitting,
            onPressed: _submit,
            leadingIcon: Icons.send_rounded,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
