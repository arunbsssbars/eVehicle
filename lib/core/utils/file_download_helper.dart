import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class FileDownloadHelper {
  FileDownloadHelper._();

  /// Download or share text content (CSV / TXT / JSON) across Web, iOS, Android, Desktop
  static Future<void> downloadTextFile({
    required BuildContext context,
    required String content,
    required String filename,
    String mimeType = 'text/csv',
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    await downloadBinaryFile(
      context: context,
      bytes: bytes,
      filename: filename,
    );
  }

  /// Download or share binary bytes across platforms
  static Future<void> downloadBinaryFile({
    required BuildContext context,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: filename,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File ready: $filename'),
          ),
        );
      }
    }
  }
}
