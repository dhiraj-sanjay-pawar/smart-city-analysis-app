import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/traffic_model.dart';
import '../../../data/repositories/traffic_repository.dart';

class TrafficScreen extends StatefulWidget {
  const TrafficScreen({super.key});

  @override
  State<TrafficScreen> createState() => _TrafficScreenState();
}

class _TrafficScreenState extends State<TrafficScreen> {
  String _searchQuery = '';
  String _categoryFilter = 'All';
  final List<String> _filters = ['All', 'Congestion', 'Diversion', 'Road Closure', 'Clear'];

  List<TrafficCondition> _conditions = [];
  List<TrafficAlert> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool _showReportForm = false;
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchTrafficData();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchTrafficData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<TrafficRepository>();
      final results = await Future.wait([
        repo.getAllConditions(),
        repo.getAlerts(),
      ]);

      if (mounted) {
        setState(() {
          _conditions = results[0] as List<TrafficCondition>;
          _alerts = results[1] as List<TrafficAlert>;
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

  List<TrafficCondition> get _filtered {
    List<TrafficCondition> list = _conditions;
    if (_categoryFilter == 'Congestion') {
      list = list.where((c) => c.severity == TrafficSeverity.heavy || c.severity == TrafficSeverity.moderate).toList();
    } else if (_categoryFilter == 'Road Closure') {
      list = list.where((c) => c.severity == TrafficSeverity.closed).toList();
    } else if (_categoryFilter == 'Clear') {
      list = list.where((c) => c.severity == TrafficSeverity.clear).toList();
    } else if (_categoryFilter == 'Diversion') {
      list = list.where((c) => c.alternativeRoute != null).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) => c.roadName.toLowerCase().contains(q) || c.area.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Color _severityColor(TrafficSeverity s) {
    switch (s) {
      case TrafficSeverity.clear: return AppColors.success;
      case TrafficSeverity.moderate: return AppColors.warning;
      case TrafficSeverity.heavy: return AppColors.error;
      case TrafficSeverity.closed: return const Color(0xFF991B1B);
    }
  }

  IconData _severityIcon(TrafficSeverity s) {
    switch (s) {
      case TrafficSeverity.clear: return Icons.check_circle_rounded;
      case TrafficSeverity.moderate: return Icons.warning_amber_rounded;
      case TrafficSeverity.heavy: return Icons.traffic_rounded;
      case TrafficSeverity.closed: return Icons.block_rounded;
    }
  }

  Future<void> _submitReport() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      _isSubmitting = false;
      _showReportForm = false;
    });
    _descController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Traffic condition reported to Nashik Traffic Control Room!'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Traffic & Route Management'),
            Text(
              'Live Route Congestion & Telemetry',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_rounded),
            tooltip: 'Report Blockage',
            onPressed: () => setState(() => _showReportForm = !_showReportForm),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchTrafficData,
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
                  // Alert ticker from API
                  if (_alerts.isNotEmpty)
                    Container(
                      color: AppColors.errorLight,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: _alerts.map((alert) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_rounded, size: 13, color: AppColors.error),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${alert.area}: ${alert.title}',
                                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.error),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  // Report form (expandable)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showReportForm
                        ? _ReportForm(controller: _descController, isSubmitting: _isSubmitting, onSubmit: _submitReport)
                        : const SizedBox.shrink(),
                  ),

                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                              onChanged: (v) => setState(() => _searchQuery = v.trim()),
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                              decoration: InputDecoration(
                                hintText: 'Search Nashik road, ghat, or corridor…',
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
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _searchQuery = ''),
                              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textLight),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Category filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _filters.map((f) {
                        final selected = f == _categoryFilter;
                        return AnimatedTap(
                          onTap: () => setState(() => _categoryFilter = f),
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

                  const SizedBox(height: 8),

                  // Traffic list
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
                                    ElevatedButton(onPressed: _fetchTrafficData, child: const Text('Retry')),
                                  ],
                                ),
                              )
                            : _filtered.isEmpty
                                ? const EmptyStateWidget(
                                    icon: Icons.traffic_rounded,
                                    title: 'No routes found',
                                    subtitle: 'Try a different filter or search term',
                                  )
                                : RefreshIndicator(
                                    onRefresh: _fetchTrafficData,
                                    color: AppColors.secondary,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      itemCount: _filtered.length,
                                      itemBuilder: (context, i) {
                                        return _TrafficTile(
                                          condition: _filtered[i],
                                          severityColor: _severityColor(_filtered[i].severity),
                                          severityIcon: _severityIcon(_filtered[i].severity),
                                        ).cardEntrance(index: i);
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
}

class _ReportForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _ReportForm({required this.controller, required this.isSubmitting, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report Road Blockage or Congestion',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe the blockage, diversion or incident…',
              hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text('Nashik Kumbh Mela Zone, Maharashtra',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium)),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Submit Report',
            isLoading: isSubmitting,
            onPressed: onSubmit,
            leadingIcon: Icons.send_rounded,
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}

class _TrafficTile extends StatelessWidget {
  final TrafficCondition condition;
  final Color severityColor;
  final IconData severityIcon;

  const _TrafficTile({
    required this.condition,
    required this.severityColor,
    required this.severityIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTap(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: condition.severity == TrafficSeverity.closed
                ? severityColor.withValues(alpha: 0.4)
                : AppColors.border,
            width: 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(severityIcon, color: severityColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(condition.roadName,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      Text(condition.area,
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMedium)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(condition.severityLabel,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: severityColor)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(condition.description,
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textMedium, height: 1.5)),
            if (condition.alternativeRoute != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alt_route_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text('Alt Route: ${condition.alternativeRoute!}',
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
