import 'package:flutter/material.dart';
import '../../core/models/property.dart';
import '../../core/models/inquiry.dart';
import '../../core/services/supabase_service.dart';

class InquiryFormSheet extends StatefulWidget {
  final Property property;

  const InquiryFormSheet({super.key, required this.property});

  @override
  State<InquiryFormSheet> createState() => _InquiryFormSheetState();
}

class _InquiryFormSheetState extends State<InquiryFormSheet> {
  final _supabaseService = SupabaseService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController(text: "Hi, I am interested in this property and would like to learn more.");
  
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isAlreadyInquired = false;

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  Future<void> _prefillUserData() async {
    final profile = await _supabaseService.getCurrentUserProfile();
    if (profile != null) {
      if (mounted) {
        setState(() {
          _nameCtrl.text = profile.fullName ?? '';
          _emailCtrl.text = _supabaseService.currentUserEmail ?? '';
          _phoneCtrl.text = profile.phone ?? '';
        });
      }
    }
  }

  Future<void> _submitInquiry() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out Name, Email, and Message.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Duplicate check (checks both user ID and email)
      final alreadyInquired = await _supabaseService.hasAlreadyInquired(widget.property.id, _emailCtrl.text.trim());
      if (alreadyInquired) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isAlreadyInquired = true;
          });
          // Auto close after 4 seconds
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) Navigator.pop(context);
          });
        }
        return;
      }

      final inquiry = Inquiry(
        id: '', // Supabase auto-generates this UUID
        propertyId: widget.property.id,
        customerName: _nameCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        status: 'New',
        createdAt: DateTime.now(),
      );

      await _supabaseService.submitInquiry(inquiry);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        
        // Auto close after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting inquiry: $e')));
      }
    }
  }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isSuccess || _isAlreadyInquired) {
      return Container(
        height: 320,
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAlreadyInquired ? Icons.info_outline_rounded : Icons.check_circle_rounded, 
              color: _isAlreadyInquired ? const Color(0xFFF59E0B) : Colors.green, 
              size: 80
            ),
            const SizedBox(height: 24),
              Text(
                _isAlreadyInquired ? 'Inquiry Already Active' : 'Inquiry Sent!', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))
              ),
              const SizedBox(height: 12),
              Text(
                _isAlreadyInquired 
                  ? 'You have already inquired about this property. An agent will be in touch with you very soon.' 
                  : 'Your message for ${widget.property.title} has been received. Our team will contact you shortly.', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600], height: 1.5, fontSize: 14)
              ),
            const SizedBox(height: 32),
            if (_isAlreadyInquired)
              Text('Thank you for your patience!', style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic, fontSize: 12)),
          ],
        ),
      );
    }

    return Padding(
      // Padding pushes the UI up if the keyboard opens
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Contact Agent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                  IconButton(icon: const Icon(Icons.close), color: theme.colorScheme.secondary.withOpacity(0.5), onPressed: () => Navigator.pop(context))
                ],
              ),
              const SizedBox(height: 16),
              
              _buildTextField('Full Name', _nameCtrl, Icons.person),
              const SizedBox(height: 12),
              _buildTextField('Email Address', _emailCtrl, Icons.email),
              const SizedBox(height: 12),
              _buildTextField('Phone Number (Optional)', _phoneCtrl, Icons.phone),
              const SizedBox(height: 12),
              
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                style: TextStyle(color: theme.colorScheme.secondary),
                decoration: InputDecoration(
                  labelText: 'Message',
                  labelStyle: const TextStyle(color: Colors.grey),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submitInquiry,
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      style: TextStyle(color: theme.colorScheme.secondary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFF59E0B)),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
