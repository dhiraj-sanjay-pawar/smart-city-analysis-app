import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../data/models/ai_predict_model.dart';
import '../bloc/ai_cubit.dart';
import '../bloc/ai_state.dart';

/// Citizen-facing safety prediction screen.
/// Allows users to check predicted safety conditions for a location + time.
/// DOES NOT expose administrative controls, dispatch buttons, or choke-point
/// probability — those are operational fields for emergency managers only.
class AiPredictScreen extends StatefulWidget {
  const AiPredictScreen({super.key});

  @override
  State<AiPredictScreen> createState() => _AiPredictScreenState();
}

class _AiPredictScreenState extends State<AiPredictScreen> {
  // ── Form state ─────────────────────────────────────────────────
  String _sector = _kSectors.first;
  String _timeWindow = _kTimeWindows.first;
  double _crowdDensity = 3.0;
  String _vehicleInflowLabel = _kVehicleInflowOptions.keys.first;
  String _weatherCondition = _kWeatherOptions.first;

  // ── Static options (backend-validated values) ──────────────────
  static const List<String> _kSectors = [
    'Sector 1 (Sangam Ghat)',
    'Sector 2 (Panchavati)',
    'Sector 3 (College Road)',
    'Sector 4 (CBS Chowk)',
    'Sector 5 (Gangapur Road)',
    'Sector 6 (Nashik Road)',
  ];

  static const List<String> _kTimeWindows = [
    '6:00 AM - 9:00 AM',
    '9:00 AM - 12:00 PM',
    '12:00 PM - 3:00 PM',
    '3:00 PM - 5:00 PM',
    '5:00 PM - 8:00 PM',
    '8:00 PM - 11:00 PM',
  ];

  static const Map<String, int> _kVehicleInflowOptions = {
    'Low (< 800/hr)': 600,
    'Moderate (800–1800/hr)': 1200,
    'High (1800–2800/hr)': 2200,
    'Very High (2800–3500/hr)': 3200,
    'Extreme (> 3500/hr)': 4000,
  };

  static const List<String> _kWeatherOptions = [
    'Dry / Clear',
    'Partly Cloudy',
    'Light Rain',
    'Heavy Rain',
    'Fog / Low Visibility',
  ];

  @override
  void initState() {
    super.initState();
    context.read<AiCubit>().resetPrediction();
  }

  void _submit() {
    final vehicleInflow = _kVehicleInflowOptions[_vehicleInflowLabel] ?? 1200;
    context.read<AiCubit>().predict(
          AiPredictRequest(
            sector: _sector,
            timeWindow: _timeWindow,
            crowdDensity: double.parse(_crowdDensity.toStringAsFixed(1)),
            vehicleInflow: vehicleInflow,
            weatherCondition: _weatherCondition,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Safety Prediction',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
      ),
      body: BlocBuilder<AiCubit, AiState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informational banner
                _buildInfoBanner(),
                const SizedBox(height: 24),

                // Form card
                _buildFormCard(state),
                const SizedBox(height: 20),

                // Results
                if (state is AiPredictLoading) _buildResultLoading(),
                if (state is AiPredictError) _buildResultError(state.message),
                if (state is AiPredictLoaded) _buildResultCard(state.result),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This tool uses AI to estimate safety conditions. Always follow official advisories from civic authorities.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.info,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildFormCard(AiState state) {
    final isLoading = state is AiPredictLoading;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check Area Safety',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fill in the details to get an AI safety assessment.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
          ),
          const SizedBox(height: 20),

          // Sector
          _buildDropdownField(
            label: 'Area / Sector',
            icon: Icons.location_on_rounded,
            value: _sector,
            items: _kSectors,
            onChanged: isLoading ? null : (v) => setState(() => _sector = v!),
          ),
          const SizedBox(height: 14),

          // Time window
          _buildDropdownField(
            label: 'Time Window',
            icon: Icons.schedule_rounded,
            value: _timeWindow,
            items: _kTimeWindows,
            onChanged: isLoading ? null : (v) => setState(() => _timeWindow = v!),
          ),
          const SizedBox(height: 14),

          // Vehicle inflow
          _buildDropdownField(
            label: 'Expected Vehicle Traffic',
            icon: Icons.directions_car_rounded,
            value: _vehicleInflowLabel,
            items: _kVehicleInflowOptions.keys.toList(),
            onChanged: isLoading
                ? null
                : (v) => setState(() => _vehicleInflowLabel = v!),
          ),
          const SizedBox(height: 14),

          // Weather condition
          _buildDropdownField(
            label: 'Weather Condition',
            icon: Icons.cloud_rounded,
            value: _weatherCondition,
            items: _kWeatherOptions,
            onChanged:
                isLoading ? null : (v) => setState(() => _weatherCondition = v!),
          ),
          const SizedBox(height: 18),

          // Crowd density slider
          _buildCrowdSlider(isLoading),
          const SizedBox(height: 22),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: isLoading ? null : _submit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search_rounded, size: 20),
              label: Text(
                isLoading ? 'Analysing...' : 'Predict Safety',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMedium, size: 20),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Row(
                          children: [
                            Icon(icon, size: 14, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrowdSlider(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Crowd Density',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${_crowdDensity.toStringAsFixed(1)} / 10',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.secondary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.secondary,
            overlayColor: AppColors.secondary.withValues(alpha: 0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: _crowdDensity,
            min: 1.0,
            max: 10.0,
            divisions: 18,
            onChanged: isLoading ? null : (v) => setState(() => _crowdDensity = v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sparse', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
            Text('Packed', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ],
    );
  }

  Widget _buildResultLoading() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          AnimatedPlaceholder(height: 160, radius: 18),
          SizedBox(height: 12),
          AnimatedPlaceholder(height: 100, radius: 16),
        ],
      ),
    );
  }

  Widget _buildResultError(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().shake();
  }

  Widget _buildResultCard(AiPredictionResult result) {
    final riskColor = _riskColor(result.riskLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Assessment',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 12),

        // Risk Score Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                riskColor.withValues(alpha: 0.9),
                riskColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: riskColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Risk Score',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '${result.overallRiskScore.toStringAsFixed(1)}',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      result.riskLevel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.primaryThreat,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ResultChip(label: 'Confidence: ${result.confidenceInterval}'),
                  const SizedBox(width: 10),
                  _ResultChip(label: 'Est. Incidents: ${result.estimatedIncidentVolume}'),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 16),

        // Context info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ContextItem(
                  icon: Icons.location_on_rounded,
                  label: 'Area',
                  value: result.sector,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _ContextItem(
                  icon: Icons.schedule_rounded,
                  label: 'Time',
                  value: result.timeWindow,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _ContextItem(
                  icon: Icons.cloud_rounded,
                  label: 'Weather',
                  value: result.weatherCondition,
                ),
              ),
            ],
          ),
        ).animate(delay: 150.ms).fadeIn(duration: 350.ms),

        if (result.actionableRecommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildRecommendations(result.actionableRecommendations),
        ],
      ],
    );
  }

  Widget _buildRecommendations(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.secondary, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Safety Guidance',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textDark,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'moderate':
        return AppColors.info;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textMedium;
    }
  }

  Color _riskBg(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return AppColors.errorLight;
      case 'high':
        return AppColors.warningLight;
      case 'moderate':
        return AppColors.infoLight;
      case 'low':
        return AppColors.successLight;
      default:
        return AppColors.backgroundAlt;
    }
  }
}

class _ResultChip extends StatelessWidget {
  final String label;
  const _ResultChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ContextItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContextItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
