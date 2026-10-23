import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_utils.dart';
import '../../transactions/domain/finance_transaction.dart';
import '../domain/finance_report.dart';

/// Writes a CSV file to the app's temporary folder and opens the system
/// share sheet (save to Files / Drive, email, messaging, ...).
class ReportExportService {
  Future<void> shareTransactionsCsv(
    List<FinanceTransaction> transactions,
    DateRange range, {
    Rect? sharePositionOrigin,
  }) async {
    if (transactions.isEmpty) {
      throw const ValidationException('There are no transactions to export.');
    }
    try {
      final dir = await getTemporaryDirectory();
      final last = range.end.subtract(const Duration(days: 1));
      final name = 'lifemate_${AppDateUtils.dayKey(range.start)}'
          '_${AppDateUtils.dayKey(last)}.csv';
      final file = File('${dir.path}/$name');
      await file.writeAsString(ReportCsv.build(transactions), flush: true);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'LifeMate transactions',
        // Required on iPad to anchor the share popover.
        sharePositionOrigin: sharePositionOrigin,
      ));
    } on FileSystemException catch (e) {
      throw UnknownException('Could not create the CSV file: ${e.message}');
    }
  }
}

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return ReportExportService();
});
