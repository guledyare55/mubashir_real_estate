import 'package:flutter/material.dart';
import '../../core/models/profile.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/utils/lease_pdf_generator.dart';

class CustomerDossierDialog extends StatefulWidget {
  final Profile customer;
  const CustomerDossierDialog({super.key, required this.customer});

  @override
  State<CustomerDossierDialog> createState() => _CustomerDossierDialogState();
}

class _CustomerDossierDialogState extends State<CustomerDossierDialog> {
  bool _isClosingDeal = false;

  // Deal Wizard State
  final _propertyCtrl = TextEditingController();
  final _rentCtrl = TextEditingController(text: r'$500');
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedDocType = 'National ID Card';
  final List<String> _docTypes = ['National ID Card', 'Passport', 'Driver\'s License', 'Resident Permit'];

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
                    labelText: 'Amount (e.g. $500)',
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
                    Expanded(child: _buildUploadZone(theme, 'Front of Document', Icons.badge_outlined, isDark)),
                    if (_selectedDocType != 'Passport') ...[
                      const SizedBox(width: 24),
                      Expanded(child: _buildUploadZone(theme, 'Back of Document', Icons.credit_card_outlined, isDark)),
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
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Finalize Lease & Generate PDF'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                      onPressed: () async {
                        if (_propertyCtrl.text.isEmpty || _startDate == null || _endDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select property and lease dates.')),
                          );
                          return;
                        }

                        // 1. Generate the PDF bytes
                        final pdfBytes = await LeasePdfGenerator.generate(
                          customer: widget.customer,
                          propertyTitle: _propertyCtrl.text.trim(),
                          startDate: _startDate!,
                          endDate: _endDate!,
                          monthlyRent: _rentCtrl.text.trim(),
                        );

                        // 2. Open the system print dialog
                        await Printing.layoutPdf(
                          onLayout: (format) async => pdfBytes,
                          name: 'Lease_Agreement_${widget.customer.fullName}.pdf',
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lease Finalized & PDF Generated!')),
                          );
                          Navigator.pop(context);
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

  Widget _buildUploadZone(ThemeData theme, String label, IconData icon, bool isDark) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50], 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 2, style: BorderStyle.none),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16), onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
