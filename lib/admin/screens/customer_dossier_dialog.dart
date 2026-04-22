import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/models/profile.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/lease_pdf_generator.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/agency_settings.dart';

class CustomerDossierDialog extends StatefulWidget {
  final Profile customer;
  const CustomerDossierDialog({super.key, required this.customer});

  @override
  State<CustomerDossierDialog> createState() => _CustomerDossierDialogState();
}

class _CustomerDossierDialogState extends State<CustomerDossierDialog> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isClosingDeal = false;
  bool _isSaving = false;

  // KYC Upload State
  Uint8List? _idFrontBytes;
  String? _idFrontName;
  Uint8List? _idBackBytes;
  String? _idBackName;
  
  late Future<AgencySettings> _settingsFuture;

  // Deal Wizard State
  final _propertyCtrl = TextEditingController();
  final _rentCtrl = TextEditingController(text: r'$500');
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedDocType = 'National ID Card';
  final List<String> _docTypes = ['National ID Card', 'Passport', 'Driver\'s License', 'Resident Permit'];

  @override
  void initState() {
    super.initState();
    _settingsFuture = _supabaseService.fetchAgencySettings();
  }

  @override
  void dispose() {
    _propertyCtrl.dispose();
    _rentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isClosingDeal ? 800 : 600,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                    children: [
                      if (_isClosingDeal) ...[
                        IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isClosingDeal = false)),
                        const SizedBox(width: 8),
                      ],
                      Text(_isClosingDeal ? 'Close New Deal' : 'Customer Dossier', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              
              if (!_isClosingDeal) ...[
                // --- DOSSIER VIEW ---
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(widget.customer.fullName?.substring(0, 1).toUpperCase() ?? 'U', style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customer.fullName ?? 'Unknown User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Joined: ${DateFormat('MMM dd, yyyy').format(widget.customer.createdAt)}', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.handshake),
                      label: const Text('Close Deal'),
                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                      onPressed: () => setState(() => _isClosingDeal = true),
                    )
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Lease History Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor.withOpacity(0.1))),
                  child: const Center(child: Text('No active leases found for this customer.', style: TextStyle(color: Colors.grey))),
                ),
                
                const SizedBox(height: 32),
                const Text('Legal Identity Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (widget.customer.idFrontUrl == null && widget.customer.idBackUrl == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.1))),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('No identity documents on file for this customer.', style: TextStyle(color: Colors.orange, fontSize: 13)),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      if (widget.customer.idFrontUrl != null)
                        Expanded(
                          child: _buildDocCard(
                            theme, 
                            'Front of ${widget.customer.idType ?? 'ID'}', 
                            widget.customer.idFrontUrl!, 
                            isDark
                          ),
                        ),
                      if (widget.customer.idBackUrl != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDocCard(
                            theme, 
                            'Back of ${widget.customer.idType ?? 'ID'}', 
                            widget.customer.idBackUrl!, 
                            isDark
                          ),
                        ),
                      ],
                    ],
                  ),

                const SizedBox(height: 32),
                const Text('Active Lease Dossier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (widget.customer.leaseUrl == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.1))),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('No archived lease dossier found.', style: TextStyle(color: Colors.blue, fontSize: 13)),
                      ],
                    ),
                  )
                else
                  _buildDocCard(
                    theme, 
                    'Generated Lease Agreement', 
                    widget.customer.leaseUrl!, 
                    isDark,
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Lease Dossier?'),
                          content: const Text('This will permanently remove the archived PDF from the system. This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true), 
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete Permanently'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await _supabaseService.deleteLeaseDocument(widget.customer.id, widget.customer.leaseUrl!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lease dossier deleted successfully.')));
                            Navigator.pop(context, true); // Refresh dashboard
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red));
                          }
                        }
                      }
                    },
                  ),
              ] else ...[
                // --- DEAL WIZARD VIEW ---
                const Text('1. Property Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _propertyCtrl,
                  decoration: InputDecoration(
                    labelText: 'Select Property/Unit',
                    hintText: 'e.g. Modern Villa - Unit 4B',
                    filled: true, fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Monthly Rent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rentCtrl,
                  decoration: InputDecoration(
                    labelText: r'Amount (e.g. $500)',
                    filled: true, fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('2. Lease Duration (From - To)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                           final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)));
                           setState(() => _startDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Text(_startDate == null ? 'Select Start Date' : DateFormat('MMM dd, yyyy').format(_startDate!), style: TextStyle(color: _startDate == null ? Colors.grey : theme.textTheme.bodyLarge?.color)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                           final date = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)));
                           setState(() => _endDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Text(_endDate == null ? 'Select End Date' : DateFormat('MMM dd, yyyy').format(_endDate!), style: TextStyle(color: _endDate == null ? Colors.grey : theme.textTheme.bodyLarge?.color)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text('3. Identity Verification (KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDocType, isExpanded: true,
                      items: _docTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (val) { if (val != null) setState(() => _selectedDocType = val); },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildUploadZone(
                        theme, 
                        _idFrontName ?? 'Front of Document', 
                        _idFrontName != null ? Icons.check_circle : Icons.badge_outlined, 
                        isDark,
                        () async {
                          final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                          if (result != null) {
                            setState(() {
                              _idFrontBytes = result.files.first.bytes;
                              _idFrontName = result.files.first.name;
                            });
                          }
                        }
                      )
                    ),
                    if (_selectedDocType != 'Passport') ...[
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildUploadZone(
                          theme, 
                          _idBackName ?? 'Back of Document', 
                          _idBackName != null ? Icons.check_circle : Icons.credit_card_outlined, 
                          isDark,
                          () async {
                            final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                            if (result != null) {
                              setState(() {
                                _idBackBytes = result.files.first.bytes;
                                _idBackName = result.files.first.name;
                              });
                            }
                          }
                        )
                      ),
                    ]
                  ],
                ),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => setState(() => _isClosingDeal = false), child: const Text('Cancel')),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                      label: Text(_isSaving ? 'Uploading Identity...' : 'Finalize Lease & Generate PDF'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                      onPressed: _isSaving ? null : () async {
                        if (_propertyCtrl.text.isEmpty || _startDate == null || _endDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select property and lease dates.')),
                          );
                          return;
                        }

                        setState(() => _isSaving = true);

                        try {
                          String? frontUrl;
                          String? backUrl;

                          // 1. Upload KYC Documents if provided
                          if (_idFrontBytes != null) {
                            frontUrl = await _supabaseService.uploadIdentityDocument(_idFrontBytes!, _idFrontName!, widget.customer.id);
                          }
                          if (_idBackBytes != null) {
                            backUrl = await _supabaseService.uploadIdentityDocument(_idBackBytes!, _idBackName!, widget.customer.id);
                          }

                          // 2. Update Customer Profile with KYC
                          await _supabaseService.updateCustomerKyc(widget.customer.id, _selectedDocType, frontUrl, backUrl);

                          // 3. Generate the PDF bytes
                          final settings = await _settingsFuture;
                          final pdfBytes = await LeasePdfGenerator.generate(
                            customer: widget.customer,
                            propertyTitle: _propertyCtrl.text.trim(),
                            startDate: _startDate!,
                            endDate: _endDate!,
                            monthlyRent: _rentCtrl.text.trim(),
                            agencyLogoUrl: settings.logoUrl,
                            agencyName: settings.name,
                            idFrontBytes: _idFrontBytes,
                            idBackBytes: _idBackBytes,
                          );

                          // 4. Archive the PDF to Cloud Storage
                          final leaseUrl = await _supabaseService.uploadLeaseDocument(pdfBytes, widget.customer.id);
                          await _supabaseService.updateCustomerLease(widget.customer.id, leaseUrl);

                          // 5. Open the system print dialog
                          await Printing.layoutPdf(
                            onLayout: (format) async => pdfBytes,
                            name: 'Lease_Agreement_${widget.customer.fullName}.pdf',
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lease Finalized, Identity Uploaded & PDF Generated!')),
                            );
                            Navigator.pop(context, true); // Return true to trigger refresh in parent
                          }
                        } catch (e) {
                           if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Upload/Save Failed: $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                    )
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocCard(ThemeData theme, String label, String url, bool isDark, {VoidCallback? onDelete}) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 40, color: theme.colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open Full Document', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: 'Delete Document',
            ),
          ),
      ],
    );
  }

  Widget _buildUploadZone(ThemeData theme, String label, IconData icon, bool isDark, VoidCallback onTap) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50], 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: icon == Icons.check_circle ? Colors.green : theme.colorScheme.primary.withOpacity(0.5), 
          width: 2, 
          style: BorderStyle.none
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16), 
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: icon == Icons.check_circle ? Colors.green : theme.colorScheme.primary),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label, 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: icon == Icons.check_circle ? Colors.green : null,
                  fontSize: icon == Icons.check_circle ? 12 : 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
