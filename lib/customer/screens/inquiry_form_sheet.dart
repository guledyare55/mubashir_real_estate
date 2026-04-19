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

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Inquiry Sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('The agent for ${widget.property.title} will contact you shortly.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      );
    }

    return Padding(
      // Padding pushes the UI up if the keyboard opens
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Contact Agent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  IconButton(icon: const Icon(Icons.close), color: Colors.black54, onPressed: () => Navigator.pop(context))
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
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey[100],
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
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
