import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';

class WalkInRegistrationDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const WalkInRegistrationDialog({super.key, required this.onSuccess});

  @override
  State<WalkInRegistrationDialog> createState() => _WalkInRegistrationDialogState();
}

class _WalkInRegistrationDialogState extends State<WalkInRegistrationDialog> {
  final _supabaseService = SupabaseService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all fields.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabaseService.registerWalkInCustomer(
        _emailCtrl.text.trim(),
        _nameCtrl.text.trim(),
        _phoneCtrl.text.trim(),
      );

      // Successfully added!
      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Walk-In Client Registered!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Walk-In Client', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Registering a physical client walking into the office.', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
            const SizedBox(height: 32),

            _buildField('Full Legal Name', _nameCtrl, Icons.person, isDark),
            const SizedBox(height: 16),
            _buildField('Email Address', _emailCtrl, Icons.email, isDark, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildField('Phone Number', _phoneCtrl, Icons.phone, isDark, keyboard: TextInputType.phone),
            
            const SizedBox(height: 48),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.how_to_reg),
                  label: Text(_isLoading ? 'Registering...' : 'Save Client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, bool isDark, {TextInputType? keyboard}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
