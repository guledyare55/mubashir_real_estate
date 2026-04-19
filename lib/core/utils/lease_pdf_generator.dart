import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/profile.dart';

class LeasePdfGenerator {
  static Future<Uint8List> generate({
    required Profile customer,
    required String propertyTitle,
    required DateTime startDate,
    required DateTime endDate,
    String monthlyRent = r"$500", // Default placeholder
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- HEADER ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MUBASHIR REAL ESTATE',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Professional Property Management Services',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('LEASE AGREEMENT',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${dateFormat.format(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 20),

            // --- PARTIES ---
            pw.Text('1. PARTIES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(
                'This Residential Lease Agreement is entered into between MUBASHIR REAL ESTATE (Landlord) and the following individual (Tenant):'),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(children: [
                    pw.Text('Tenant Name: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customer.fullName ?? 'N/A'),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Text('Phone Number: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customer.phone ?? 'N/A'),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Text('Email: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customer.id.substring(0, 8)), // Just a placeholder for ID
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // --- PREMISES & TERM ---
            pw.Text('2. THE PREMISES & TERM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(
                'Landlord leases to Tenant the following property: ${propertyTitle.toUpperCase()} for a fixed term beginning on ${dateFormat.format(startDate)} and ending on ${dateFormat.format(endDate)}.'),
            pw.SizedBox(height: 20),

            // --- RENT & DEPOSIT ---
            pw.Text('3. RENT AND PAYMENTS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Bullet(text: 'The monthly rent is set at $monthlyRent payable by the 1st of each month.'),
            pw.SizedBox(height: 4),
            pw.Bullet(text: 'A security deposit may be required prior to move-in as per local law.'),
            pw.SizedBox(height: 20),

            // --- STANDARD TERMS ---
            pw.Text('4. TERMS AND CONDITIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Paragraph(
                text:
                    'OCCUPANCY: The premises shall be used strictly as a residential dwelling for the Tenant and immediate family only. Any subletting or industrial use of the property is strictly prohibited without written consent from the Landlord.'),
            pw.Paragraph(
                text:
                    'MAINTENANCE: The Tenant agrees to maintain the property in a clean and sanitary condition. Any major structural damage or utility failure must be reported to Mubashir Real Estate immediately via the official support channels.'),
            pw.Paragraph(
                text:
                    'RIGHT OF ENTRY: The Landlord reserves the right to enter the premises for inspection, repairs, or emergency purposes with a minimum of 24 hours notice to the Tenant, except in cases of immediate emergency.'),
            pw.SizedBox(height: 40),

            // --- SIGNATURES ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 200, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)))),
                    pw.SizedBox(height: 4),
                    pw.Text('Tenant Signature', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 200, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)))),
                    pw.SizedBox(height: 4),
                    pw.Text('Landlord (Mubashir Real Estate)', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Text('This document is a legally binding contract in accordance with local real estate laws.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
