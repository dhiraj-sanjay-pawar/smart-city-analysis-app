import 'dart:typed_data';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';

class ExportResult {
  final String fileName;
  final String format;
  final int byteLength;
  final Uint8List bytes;

  ExportResult({
    required this.fileName,
    required this.format,
    required this.byteLength,
    required this.bytes,
  });
}

class ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Exports PDF or Excel report from GET /reports/export
  Future<ExportResult> exportReport({
    required String format, // 'pdf' or 'excel' (or 'xlsx')
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'format': format.toLowerCase(),
    };
    if (category != null) queryParams['category'] = category;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final bytes = await _apiClient.downloadBytes(
      ApiConfig.reportsExport,
      queryParameters: queryParams,
    );

    final ext = format.toLowerCase().contains('excel') || format.toLowerCase().contains('xls') ? 'xlsx' : 'pdf';
    final fileName = 'SmartCity_Analytics_Report_${DateTime.now().millisecondsSinceEpoch}.$ext';

    return ExportResult(
      fileName: fileName,
      format: ext,
      byteLength: bytes.length,
      bytes: bytes,
    );
  }
}
