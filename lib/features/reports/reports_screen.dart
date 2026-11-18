import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/reports_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  ComplaintStatus? _selectedStatus;
  List<ComplaintModel> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  Future<void> _fetchIncidents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = context.read<AuthRepository>();
      final currentUser = authRepo.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _complaints = [];
            _errorMessage = 'Please sign in to view your filed grievances and track municipal resolution.';
            _isLoading = false;
          });
        }
        return;
      }

      final repo = context.read<ComplaintRepository>();
      final list = await repo.getMyReports(
        userId: currentUser.id,
        status: _selectedStatus,
        searchQuery: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _complaints = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleExport(String format) async {
    setState(() => _isExporting = true);
    try {
      final reportsRepo = context.read<ReportsRepository>();
      final result = await reportsRepo.exportReport(
        format: format,
        category: _selectedStatus?.name,
      );

      if (!mounted) return;
      setState(() => _isExporting = false);

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.download_done_rounded, color: AppColors.success, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Report Exported Successfully',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Exporting reports in $format format...',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      format == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded,
                      color: format == 'pdf' ? AppColors.error : AppColors.success,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result.fileName,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('${(result.byteLength / 1024).toStringAsFixed(1)} KB • Ready for municipal dispatch',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMedium)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reports & Grievances'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined, color: Colors.white),
            tooltip: 'Export Reports',
            onSelected: (fmt) => _handleExport(fmt),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_view_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 10),
                    Text('Export as Excel (.xlsx)'),
                  ],
                ),
              ),
            ],
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
                  // Search Bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (v) {
                                _searchQuery = v.trim();
                                _fetchIncidents();
                              },
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                              decoration: InputDecoration(
                                hintText: 'Search grievances by title or location...',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
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
                              onTap: () {
                                setState(() => _searchQuery = '');
                                _fetchIncidents();
                              },
                              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textLight),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Filter tabs
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            isSelected: _selectedStatus == null,
                            onTap: () {
                              setState(() => _selectedStatus = null);
                              _fetchIncidents();
                            },
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Submitted',
                            isSelected: _selectedStatus == ComplaintStatus.submitted,
                            onTap: () {
                              setState(() => _selectedStatus = ComplaintStatus.submitted);
                              _fetchIncidents();
                            },
                            color: AppColors.statusSubmitted,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'In Progress',
                            isSelected: _selectedStatus == ComplaintStatus.inProgress,
                            onTap: () {
                              setState(() => _selectedStatus = ComplaintStatus.inProgress);
                              _fetchIncidents();
                            },
                            color: AppColors.statusInProgress,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Resolved',
                            isSelected: _selectedStatus == ComplaintStatus.resolved,
                            onTap: () {
                              setState(() => _selectedStatus = ComplaintStatus.resolved);
                              _fetchIncidents();
                            },
                            color: AppColors.statusResolved,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Rejected',
                            isSelected: _selectedStatus == ComplaintStatus.rejected,
                            onTap: () {
                              setState(() => _selectedStatus = ComplaintStatus.rejected);
                              _fetchIncidents();
                            },
                            color: AppColors.statusRejected,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.divider),

                  // Count & API Status indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          '${_complaints.length} incident${_complaints.length != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sync_rounded, size: 12, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'Live Synced',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                        : _errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                                      const SizedBox(height: 12),
                                      Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(color: AppColors.textMedium, fontSize: 13),
                                      ),
                                      const SizedBox(height: 16),
                                      if (context.read<AuthRepository>().currentUser == null)
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.login_rounded, size: 18),
                                          label: const Text('Sign In to Account'),
                                          onPressed: () => context.go('/login'),
                                        )
                                      else
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: _fetchIncidents,
                                          child: const Text('Retry'),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : _complaints.isEmpty
                                ? RefreshIndicator(
                                    onRefresh: _fetchIncidents,
                                    color: AppColors.secondary,
                                    child: LayoutBuilder(
                                      builder: (context, viewportConstraints) => SingleChildScrollView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: viewportConstraints.maxHeight,
                                          ),
                                          child: _buildEmpty(),
                                        ),
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _fetchIncidents,
                                    color: AppColors.secondary,
                                    child: ListView.builder(
                                      itemCount: _complaints.length,
                                      padding: const EdgeInsets.only(bottom: 24),
                                      itemBuilder: (context, i) {
                                        final c = _complaints[i];
                                        return _ComplaintTile(
                                          complaint: c,
                                          onTap: () => _showDetail(c),
                                        ).animate(delay: (i * 40).ms).fadeIn(duration: 250.ms).slideX(begin: 0.05, end: 0);
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded, size: 56, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              AppStrings.noComplaints,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Grievances registered by you will appear here with live resolution telemetry.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('File a Complaint'),
              onPressed: () => context.push('/complaints/new'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ComplaintDetailSheet(complaint: complaint),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onTap;

  const _ComplaintTile({required this.complaint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    complaint.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: complaint.status, small: true),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  complaint.id,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  complaint.categoryLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textMedium,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM yy').format(complaint.submittedAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    complaint.location,
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMedium),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintDetailSheet extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintDetailSheet({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      complaint.id,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  StatusBadge(status: complaint.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                complaint.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMedium,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              _detailRow(Icons.category_rounded, 'Category', complaint.categoryLabel),
              _detailRow(Icons.location_on_rounded, 'Location', complaint.location),
              _detailRow(
                Icons.calendar_today_rounded,
                'Submitted',
                DateFormat('d MMMM yyyy, h:mm a').format(complaint.submittedAt),
              ),
              const SizedBox(height: 20),
              Text(
                'Status Timeline',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...complaint.statusHistory.asMap().entries.map((entry) {
                final i = entry.key;
                final h = entry.value;
                final isLast = i == complaint.statusHistory.length - 1;
                return _TimelineItem(
                  status: h.status,
                  timestamp: h.timestamp,
                  note: h.note,
                  isLast: isLast,
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ComplaintStatus status;
  final DateTime timestamp;
  final String note;
  final bool isLast;

  const _TimelineItem({
    required this.status,
    required this.timestamp,
    required this.note,
    required this.isLast,
  });

  Color get _color {
    switch (status) {
      case ComplaintStatus.submitted:
        return AppColors.statusSubmitted;
      case ComplaintStatus.inProgress:
        return AppColors.statusInProgress;
      case ComplaintStatus.resolved:
        return AppColors.statusResolved;
      case ComplaintStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  String get _label {
    switch (status) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 4),
                ],
              ),
            ),
            if (!isLast) Container(width: 2, height: 48, color: AppColors.divider),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _color,
                  ),
                ),
                Text(
                  DateFormat('d MMM yyyy, h:mm a').format(timestamp),
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
