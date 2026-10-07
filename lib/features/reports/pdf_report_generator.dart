import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/models/journey.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/signatory_config.dart';

class PdfReportGenerator {
  PdfReportGenerator._();

  /// Build bytes for Single Journey Official Slip
  static Future<Uint8List> buildJourneySlipPdfBytes({
    required Journey journey,
    SignatoryConfig? signatoryConfig,
    bool includeDriver = true,
  }) async {
    final pdf = pw.Document();
    final defaultSig = signatoryConfig ??
        SignatoryConfig(
          enableSignatory1: includeDriver,
          signatory1Name: journey.driverName,
          signatory2Name: journey.approvedBy ?? journey.officerName,
        );

    final sig = defaultSig.copyWith(
      enableSignatory1: includeDriver ? defaultSig.enableSignatory1 : false,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 1.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GOVERNMENT OF UTTAR PRADESH',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        journey.department.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'OFFICIAL VEHICLE JOURNEY SLIP',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Journey ID: ${journey.id}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(journey.journeyDate)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Status: ${journey.status.label}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Journey Particulars Table
            pw.Text(
              '1. Journey Details',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _tableRow('Vehicle Registration No.', journey.vehicleRegistration,
                    'Vehicle Model', journey.vehicleModel),
                if (includeDriver)
                  _tableRow('Assigned Driver', journey.driverName,
                      'Controlling Officer', journey.officerName)
                else
                  _tableRow('Controlling Officer', journey.officerName,
                      'Accompanying Staff', journey.accompanyingOfficers ?? 'None'),
                _tableRow(
                  'Traveling Officer / User',
                  journey.isSubordinateJourney
                      ? '${journey.userOfficerName} (${journey.userOfficerDesignation}) [Subordinate Usage]'
                      : '${journey.userOfficerName} (${journey.userOfficerDesignation})',
                  'Logbook Row Signature',
                  journey.officerSignatureText != null
                      ? '✍️ ${journey.officerSignatureText!}'
                      : journey.userOfficerName,
                ),
                _tableRow('Department / Division', journey.department,
                    'Office', journey.office),
                _tableRow('Starting Location', journey.startLocation,
                    'Final Destination', journey.destination),
                _tableRow('Start Time',
                    DateFormat('hh:mm a').format(journey.startTime),
                    'End Time',
                    journey.endTime != null
                        ? DateFormat('hh:mm a').format(journey.endTime!)
                        : 'In Transit'),
                if (includeDriver)
                  _tableRow('Travel Purpose', journey.purpose,
                      'Accompanying Staff', journey.accompanyingOfficers ?? 'None')
                else
                  _tableRow('Travel Purpose', journey.purpose,
                      'Approval Status', journey.status.label),
              ],
            ),
            pw.SizedBox(height: 16),

            // Odometer & Distance Calculation
            pw.Text(
              '2. Odometer & Distance Verification',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _th('Opening Odometer'),
                    _th('Closing Odometer'),
                    _th('Official Distance (KM)'),
                    _th('GPS Distance (KM)'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _td('${journey.openingOdometer.toStringAsFixed(1)} KM'),
                    _td(journey.closingOdometer != null
                        ? '${journey.closingOdometer!.toStringAsFixed(1)} KM'
                        : '-'),
                    _td('${journey.calculatedDistance.toStringAsFixed(1)} KM',
                        isBold: true),
                    _td(journey.gpsDistance != null
                        ? '${journey.gpsDistance!.toStringAsFixed(1)} KM'
                        : '-'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Remarks & Approval Details
            pw.Text(
              '3. Certification & Approvals',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Remarks: ${journey.remarks ?? "Official journey logged digitally via eVehicle LogBook."}'),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      'Approval Info: ${journey.approvedBy != null ? "Approved by ${journey.approvedBy!} on ${journey.approvedAt != null ? DateFormat('dd/MM/yyyy hh:mm a').format(journey.approvedAt!) : ""}" : "Under Verification"}'),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (includeDriver && sig.enableSignatory1 && sig.signatory1Title.trim().isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text(sig.signatory1Title,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (sig.signatory1Name.trim().isNotEmpty)
                        pw.Text('(${sig.signatory1Name})',
                            style: const pw.TextStyle(fontSize: 8)),
                    ],
                  )
                else
                  pw.SizedBox(),
                if (sig.enableSignatory3 &&
                    sig.signatory3Title != null &&
                    sig.signatory3Title!.trim().isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text(sig.signatory3Title!,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (sig.signatory3Name != null &&
                          sig.signatory3Name!.trim().isNotEmpty)
                        pw.Text('(${sig.signatory3Name!})',
                            style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                if (sig.enableSignatory2 && sig.signatory2Title.trim().isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text(sig.signatory2Title,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (sig.signatory2Name.trim().isNotEmpty)
                        pw.Text('(${sig.signatory2Name})',
                            style: const pw.TextStyle(fontSize: 8)),
                    ],
                  )
                else
                  pw.SizedBox(),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Generated via eVehicle LogBook System • Official Audit Timestamp: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generate & Preview Single Journey Official Slip in Interactive Full-Screen Modal with Driver Toggle
  static Future<void> generateJourneySlip({
    required BuildContext context,
    required Journey journey,
    SignatoryConfig? signatoryConfig,
    bool initialIncludeDriver = true,
  }) async {
    bool includeDriver = initialIncludeDriver;

    await showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Journey Slip (${journey.id})'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
              actions: [
                // Quick Toggle Pill for Driver Details
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setDialogState(() {
                        includeDriver = !includeDriver;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: includeDriver
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: includeDriver ? Colors.white54 : Colors.amberAccent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            includeDriver
                                ? Icons.person_outline
                                : Icons.person_off_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            includeDriver ? 'Driver: ON' : 'Driver: OFF (Removed)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_outlined),
                  tooltip: 'Slip Configuration',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (bctx) => StatefulBuilder(
                        builder: (context, setBtmState) {
                          return SafeArea(
                            child: Material(
                              type: MaterialType.transparency,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Journey Slip Options',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Configure sections to include or exclude in the official PDF slip.',
                                      style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    SwitchListTile(
                                      title: const Text(
                                        'Include Driver Details & Signature',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                      ),
                                      subtitle: const Text(
                                        'When turned off, driver name, row, and signature line are completely omitted.',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      value: includeDriver,
                                      activeThumbColor: Colors.blue,
                                      onChanged: (val) {
                                        setBtmState(() => includeDriver = val);
                                        setDialogState(() => includeDriver = val);
                                        Navigator.pop(bctx);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share / Save PDF',
                  onPressed: () async {
                    final bytes = await buildJourneySlipPdfBytes(
                      journey: journey,
                      signatoryConfig: signatoryConfig,
                      includeDriver: includeDriver,
                    );
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: 'Journey_Slip_${journey.id}.pdf',
                    );
                  },
                ),
              ],
            ),
            body: PdfPreview(
              build: (format) async => buildJourneySlipPdfBytes(
                journey: journey,
                signatoryConfig: signatoryConfig,
                includeDriver: includeDriver,
              ),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: 'Journey_Slip_${journey.id}.pdf',
            ),
          );
        },
      ),
    );
  }

  /// Build bytes for Government Standard Monthly Log Book Register
  static Future<Uint8List> buildMonthlyLogBookPdfBytes({
    required Vehicle vehicle,
    required String monthYear,
    required List<Journey> journeys,
    String? organizationName,
    String? department,
    Map<String, bool>? visibleColumns,
    SignatoryConfig? signatoryConfig,
  }) async {
    final pdf = pw.Document();

    final sig = signatoryConfig ??
        SignatoryConfig(
          signatory1Name: vehicle.assignedDriverName,
          signatory2Name: 'Dr. S. K. Verma (EE)',
        );

    final cols = visibleColumns ??
        {
          'sno': true,
          'date': true,
          'driver': true,
          'from': true,
          'to': true,
          'purpose': true,
          'opening': true,
          'closing': true,
          'distance': true,
          'status': true,
          'signatures': true,
        };

    final totalDistance =
        journeys.fold(0.0, (sum, j) => sum + j.calculatedDistance);

    // Build dynamic headers and column widths
    final headers = <pw.Widget>[];
    final columnWidths = <int, pw.TableColumnWidth>{};
    int colIdx = 0;

    if (cols['sno'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('S.No',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FixedColumnWidth(28);
    }

    if (cols['date'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Date',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FixedColumnWidth(48);
    }

    if (cols['driver'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Driver Name',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FixedColumnWidth(60);
    }

    if (cols['from'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('From (Origin)',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FlexColumnWidth(1.4);
    }

    if (cols['to'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('To (Destination)',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FlexColumnWidth(1.4);
    }

    if (cols['purpose'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Purpose of Travel',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FlexColumnWidth(2.0);
    }

    if (cols['opening'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Opening KM',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FixedColumnWidth(48);
    }

    if (cols['closing'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Closing KM',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FixedColumnWidth(48);
    }

    if (cols['distance'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Dist (KM)',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FixedColumnWidth(42);
    }

    if (cols['status'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Status',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FixedColumnWidth(48);
    }

    if (cols['officer_signature'] == true || cols['officer_sig'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Signature of Traveling Officer',
              style:
                  pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FixedColumnWidth(75);
    }

    if (cols['signatures'] == true) {
      headers.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('Officer Initial',
              style:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      );
      columnWidths[colIdx++] = const pw.FixedColumnWidth(55);
    }

    final deptUpper = (department ?? 'Public Works Department').toUpperCase();
    final orgUpper = (organizationName ?? 'Government of Uttar Pradesh').toUpperCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return [
            // Government Header Banner
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '$orgUpper • $deptUpper',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'OFFICIAL MONTHLY VEHICLE LOG BOOK REGISTER',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Month: $monthYear',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Vehicle No: ${vehicle.registrationNumber} (${vehicle.make} ${vehicle.model})',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Log Book Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: columnWidths,
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: headers,
                ),
                for (int i = 0; i < journeys.length; i++) ...[
                  pw.TableRow(
                    children: [
                      if (cols['sno'] == true) _td('${i + 1}'),
                      if (cols['date'] == true)
                        _td(DateFormat('dd/MM').format(journeys[i].journeyDate)),
                      if (cols['driver'] == true)
                        _td(journeys[i].driverName.split(' ')[0]),
                      if (cols['from'] == true)
                        _td(journeys[i].startLocation),
                      if (cols['to'] == true)
                        _td(journeys[i].destination),
                      if (cols['purpose'] == true)
                        _td(journeys[i].purpose),
                      if (cols['opening'] == true)
                        _td(journeys[i].openingOdometer.toStringAsFixed(0)),
                      if (cols['closing'] == true)
                        _td(journeys[i].closingOdometer?.toStringAsFixed(0) ?? '-'),
                      if (cols['distance'] == true)
                        _td(journeys[i].calculatedDistance.toStringAsFixed(1),
                            isBold: true),
                      if (cols['status'] == true)
                        _td(journeys[i].status.label.split(' ').first),
                      if (cols['officer_sig'] == true || cols['officer_signature'] == true)
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                '✍️ ${journeys[i].userOfficerName}',
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue900,
                                ),
                              ),
                              pw.Text(
                                journeys[i].userOfficerDesignation,
                                style: const pw.TextStyle(
                                  fontSize: 6.5,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
            pw.SizedBox(height: 10),

            // Total Summary Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'TOTAL MONTHLY DISTANCE: ',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${totalDistance.toStringAsFixed(1)} KM',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Signatures
            if (cols['signatures'] == true) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (sig.enableSignatory1 && sig.signatory1Title.trim().isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 170, height: 1, color: PdfColors.grey700),
                        pw.SizedBox(height: 4),
                        pw.Text(sig.signatory1Title,
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        if (sig.signatory1Name.trim().isNotEmpty)
                          pw.Text('(${sig.signatory1Name})',
                              style: const pw.TextStyle(fontSize: 8)),
                      ],
                    )
                  else
                    pw.SizedBox(),
                  if (sig.enableSignatory3 &&
                      sig.signatory3Title != null &&
                      sig.signatory3Title!.trim().isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 170, height: 1, color: PdfColors.grey700),
                        pw.SizedBox(height: 4),
                        pw.Text(sig.signatory3Title!,
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        if (sig.signatory3Name != null &&
                            sig.signatory3Name!.trim().isNotEmpty)
                          pw.Text('(${sig.signatory3Name!})',
                              style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  if (sig.enableSignatory2 && sig.signatory2Title.trim().isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(width: 170, height: 1, color: PdfColors.grey700),
                        pw.SizedBox(height: 4),
                        pw.Text(sig.signatory2Title,
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        if (sig.signatory2Name.trim().isNotEmpty)
                          pw.Text('(${sig.signatory2Name})',
                              style: const pw.TextStyle(fontSize: 8)),
                      ],
                    )
                  else
                    pw.SizedBox(),
                ],
              ),
              pw.SizedBox(height: 8),
            ],
            pw.Center(
              child: pw.Text(
                'Certified that all vehicle journeys recorded in this log book were strictly for official government duty.',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generate & Preview Monthly Log Book in Interactive Full-Screen Modal
  static Future<void> generateMonthlyLogBookPdf({
    required BuildContext context,
    required Vehicle vehicle,
    required String monthYear,
    required List<Journey> journeys,
    String? organizationName,
    String? department,
    Map<String, bool>? visibleColumns,
    SignatoryConfig? signatoryConfig,
  }) async {
    final pdfBytes = await buildMonthlyLogBookPdfBytes(
      vehicle: vehicle,
      monthYear: monthYear,
      journeys: journeys,
      organizationName: organizationName,
      department: department,
      visibleColumns: visibleColumns,
      signatoryConfig: signatoryConfig,
    );

    if (context.mounted) {
      await showDialog(
        context: context,
        useSafeArea: false,
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text('Monthly Log Book ($monthYear)'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share / Save PDF',
                onPressed: () async {
                  final reg = vehicle.registrationNumber.replaceAll(' ', '_');
                  await Printing.sharePdf(
                    bytes: pdfBytes,
                    filename: 'Monthly_LogBook_${reg}_$monthYear.pdf',
                  );
                },
              ),
            ],
          ),
          body: PdfPreview(
            build: (format) async => pdfBytes,
            canChangeOrientation: true,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: 'Monthly_LogBook_${vehicle.registrationNumber}_$monthYear.pdf',
          ),
        ),
      );
    }
  }

  static pw.TableRow _tableRow(
      String label1, String val1, String label2, String val2) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label1,
                  style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text(val1, style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label2,
                  style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text(val2, style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _td(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
