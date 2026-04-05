import 'package:flutter/material.dart';
import '../../core/models/profile.dart';

class IdentityUploadDialog extends StatefulWidget {
  final Profile customer;
  const IdentityUploadDialog({super.key, required this.customer});

  @override
  State<IdentityUploadDialog> createState() => _IdentityUploadDialogState();
}

class _IdentityUploadDialogState extends State<IdentityUploadDialog> {
  String _selectedDocType = 'National ID Card';
  final List<String> _docTypes = [
    'National ID Card',
    'Passport',
    'Driver\'s License',
    'Resident Permit'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Identity Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Collecting KYC documents for ${widget.customer.fullName ?? 'Unknown User'}',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
              ),
              const SizedBox(height: 32),

              const Text('Document Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDocType,
                    isExpanded: true,
                    items: _docTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDocType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _buildUploadZone(
                      theme,
                      'Front of Document',
                      Icons.badge_outlined,
                      isDark,
                    ),
                  ),
                  if (_selectedDocType != 'Passport') ...[
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildUploadZone(
                        theme,
                        'Back of Document',
                        Icons.credit_card_outlined,
                        isDark,
                      ),
                    ),
                  ]
                ],
              ),

              const SizedBox(height: 48),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.security),
                    label: const Text('Securely Save Identity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // Trigger Cloudflare R2 Upload in the future
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Identity Documents Saved Successfully!')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadZone(ThemeData theme, String label, IconData icon, bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50], // Lighter color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.5),
          width: 2,
          style: BorderStyle.none, // We will use a dashed look in real CSS/Decorations, but simple for now
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Future: Open File Picker
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Click to browse files',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
