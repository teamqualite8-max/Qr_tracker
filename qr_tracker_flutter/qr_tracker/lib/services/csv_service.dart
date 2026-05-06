// lib/services/csv_service.dart

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'database_service.dart';

class CsvImportResult {
  final int imported;
  final int skipped;
  final int total;
  final String? error;

  CsvImportResult({
    required this.imported,
    required this.skipped,
    required this.total,
    this.error,
  });

  bool get success => error == null;
}

class CsvService {
  final DatabaseService _db = DatabaseService();

  Future<CsvImportResult> importPartsFromCsv() async {
    try {
      // Open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return CsvImportResult(
          imported: 0,
          skipped: 0,
          total: 0,
          error: 'No file selected',
        );
      }

      final file = result.files.first;
      String content;

      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        return CsvImportResult(
          imported: 0,
          skipped: 0,
          total: 0,
          error: 'Could not read file',
        );
      }

      // Parse CSV
      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(content);

      if (rows.isEmpty) {
        return CsvImportResult(
          imported: 0,
          skipped: 0,
          total: 0,
          error: 'CSV file is empty',
        );
      }

      // Extract part IDs — support:
      // 1. Single column CSV: each row is a part ID
      // 2. Multi-column: first column or column named "part_id" / "id"
      final List<String> partIds = [];

      // Check if first row is a header
      bool hasHeader = false;
      int partIdColumnIndex = 0;

      if (rows.isNotEmpty) {
        final firstRow = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
        final knownHeaders = ['part_id', 'partid', 'id', 'part', 'code', 'qr_code', 'qrcode'];
        for (int i = 0; i < firstRow.length; i++) {
          if (knownHeaders.contains(firstRow[i])) {
            hasHeader = true;
            partIdColumnIndex = i;
            break;
          }
        }
      }

      final dataRows = hasHeader ? rows.skip(1).toList() : rows;

      for (final row in dataRows) {
        if (row.isEmpty) continue;
        final cellIndex = partIdColumnIndex < row.length ? partIdColumnIndex : 0;
        final id = row[cellIndex].toString().trim();
        if (id.isNotEmpty) {
          partIds.add(id);
        }
      }

      if (partIds.isEmpty) {
        return CsvImportResult(
          imported: 0,
          skipped: 0,
          total: 0,
          error: 'No valid part IDs found in CSV',
        );
      }

      // Bulk insert
      final inserted = await _db.bulkInsertParts(partIds);
      final skipped = partIds.length - inserted;

      return CsvImportResult(
        imported: inserted,
        skipped: skipped,
        total: partIds.length,
      );
    } catch (e) {
      return CsvImportResult(
        imported: 0,
        skipped: 0,
        total: 0,
        error: 'Import failed: ${e.toString()}',
      );
    }
  }
}
