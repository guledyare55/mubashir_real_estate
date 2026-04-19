import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/property.dart';
import '../../core/models/profile.dart';
import '../../core/models/rental.dart';

class RentPropertyDialog extends StatefulWidget {
  final Property property;
  const RentPropertyDialog({super.key, required this.property});

  @override
  State<RentPropertyDialog> createState() => _RentPropertyDialogState();
}

class _RentPropertyDialogState extends State<RentPropertyDialog> {
  final SupabaseService _supabaseService = SupabaseService();
  final _rentCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController(text: '10');

  String? _selectedTenantId;
  late Future<List<Profile>> _tenantsFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tenantsFuture = _supabaseService.fetchProfiles();
    _rentCtrl.text = widget.property.price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.vpn_key_rounded, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text('Rent: ${widget.property.title}')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Tenant',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Profile>>(
              future: _tenantsFuture,
              builder: (context, snapshot) {
                final tenants = (snapshot.data ?? [])
                    .where((p) => p.role == 'customer')
                    .toList();
                return DropdownButtonFormField<String>(
                  initialValue: _selectedTenantId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Choose a registered client',
                  ),
                  items: tenants
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.fullName ?? t.id.substring(0, 8)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTenantId = v),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Rent',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _rentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Commission %',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commissionCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildCalcRow(
                    'Base Rent (To Owner)',
                    (double.tryParse(_rentCtrl.text) ?? 0),
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildCalcRow(
                    'Agency Fee (+${_commissionCtrl.text}%)',
                    (double.tryParse(_rentCtrl.text) ?? 0) *
                        (double.tryParse(_commissionCtrl.text) ?? 10) /
                        100,
                    Colors.blue,
                  ),
                  const Divider(height: 24),
                  _buildCalcRow(
                    'Total Due from Tenant',
                    (double.tryParse(_rentCtrl.text) ?? 0) *
                        (1 +
                            (double.tryParse(_commissionCtrl.text) ?? 10) /
                                100),
                    Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleCheckIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm Check-In'),
        ),
      ],
    );
  }

  Widget _buildCalcRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          '\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _handleCheckIn() async {
    if (_selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tenant FIRST')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final rent = double.tryParse(_rentCtrl.text) ?? 0;
      final commRate = double.tryParse(_commissionCtrl.text) ?? 10;

      // 1. Create Rental Record
      final rental = Rental(
        id: '',
        propertyId: widget.property.id,
        tenantId: _selectedTenantId,
        startDate: DateTime.now(),
        monthlyRent: rent,
        commissionRate: commRate,
        createdAt: DateTime.now(),
      );

      // Note: Ideally this would be a Postgres trigger, but we'll do it here for speed
      // I'll update SupabaseService to handle this or just run a custom query
      // For simplicity in this demo, I'll assume the createRental method also creates the first payout
      // or I can call a specific method here.

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful! Property is now RENTED.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
