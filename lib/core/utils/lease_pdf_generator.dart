import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/profile.dart';

class LeasePdfGenerator {
  static Future<Uint8List> generate({
    required Profile customer,
    required String propertyTitle,
    required DateTime startDate,
    required DateTime endDate,
    String monthlyRent = r"$500",
    String? agencyLogoUrl,
    String? agencyName,
    Uint8List? idFrontBytes,
    Uint8List? idBackBytes,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM dd, yyyy');

    pw.ImageProvider? logoImage;
    if (agencyLogoUrl != null && agencyLogoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(agencyLogoUrl));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading agency logo for PDF: $e');
      }
    }

    // --- PAGE 1: LEASE AGREEMENT ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // --- PREMIUM CENTERED HEADER ---
            pw.Center(
              child: pw.Column(
                children: [
                  if (logoImage != null) ...[
                    pw.Container(
                      width: 50,
                      height: 50,
                      child: pw.Image(logoImage),
                    ),
                    pw.SizedBox(height: 12),
                  ],
                  pw.Text(agencyName?.toUpperCase() ?? 'MUBASHIR REAL ESTATE',
                      style: pw.TextStyle(
                          fontSize: 20, 
                          fontWeight: pw.FontWeight.bold, 
                          color: PdfColors.blue900,
                          letterSpacing: 1.1,
                      )),
                  pw.SizedBox(height: 2),
                  pw.Text('PREMIUM PROPERTY MANAGEMENT & REAL ESTATE SERVICES',
                      style: pw.TextStyle(
                        fontSize: 8, 
                        color: PdfColors.grey600,
                        letterSpacing: 1.5,
                        fontWeight: pw.FontWeight.bold,
                      )),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.blue900),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('OFFICIAL LEASE AGREEMENT',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text('Ref: ${customer.id.substring(0, 8).toUpperCase()} / ${dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 16),

            // --- PARTIES ---
            pw.Text('1. PARTIES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 8),
            pw.Text(
                'This Residential Lease Agreement is entered into between ${agencyName ?? 'MUBASHIR REAL ESTATE'} (Landlord) and the following individual (Tenant):',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TENANT FULL NAME', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(customer.fullName ?? 'N/A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(width: 40),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CONTACT NUMBER', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(customer.phone ?? 'N/A', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
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
                    'MAINTENANCE: The Tenant agrees to maintain the property in a clean and sanitary condition. Any major structural damage or utility failure must be reported to ${agencyName ?? 'Mubashir Real Estate'} immediately via the official support channels.'),
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
                    pw.Text('Landlord (${agencyName ?? 'Mubashir Real Estate'})', style: pw.TextStyle(fontSize: 10)),
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

    // --- PAGE 2: IDENTITY DOCUMENTS (KYC) ---
    if (idFrontBytes != null || idBackBytes != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('APPENDIX A: TENANT IDENTITY VERIFICATION',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 8),
                pw.Text('The following identity documents were provided by ${customer.fullName} for legal compliance.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 32),
                
                if (idFrontBytes != null) ...[
                  pw.Text('IDENTITY DOCUMENT (FRONT)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Container(
                      height: 250,
                      child: pw.Image(pw.MemoryImage(idFrontBytes), fit: pw.BoxFit.contain),
                    ),
                  ),
                  pw.SizedBox(height: 40),
                ],

                if (idBackBytes != null) ...[
                  pw.Text('IDENTITY DOCUMENT (BACK)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Container(
                      height: 250,
                      child: pw.Image(pw.MemoryImage(idBackBytes), fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
                
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Mubashir Real Estate - Secure Compliance Records', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    pw.Text('Page 2 of 2', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
