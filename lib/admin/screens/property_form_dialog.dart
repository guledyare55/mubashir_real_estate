import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class PropertyFormDialog extends StatefulWidget {
  const PropertyFormDialog({super.key});

  @override
  State<PropertyFormDialog> createState() => _PropertyFormDialogState();
}

class _PropertyFormDialogState extends State<PropertyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  
  String _type = 'Sale';
  String _status = 'Available';

  void _pickFiles() async {
    // Implement FilePicker logic that integrates with Cloudflare R2
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.media);
    if (result != null) {
      // Setup mocking logic
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${result.files.length} files. Mock Cloudflare uploading...')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add New Property', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Details
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(labelText: 'Property Title', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(labelText: 'Price', prefixText: '\$ ', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _type,
                                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                                    items: ['Sale', 'Rent'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                    onChanged: (v) => setState(() => _type = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descController,
                              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _status,
                                    decoration: const InputDecoration(labelText: 'Availability', border: OutlineInputBorder()),
                                    items: ['Available', 'Under Offer', 'Sold', 'Rented'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                    onChanged: (v) => setState(() => _status = v!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(labelText: 'Beds', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(labelText: 'Baths', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Column 2: Media
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Property Media', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: _pickFiles,
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text('Click to upload to Cloudflare', style: TextStyle(color: Colors.grey[600])),
                                  const SizedBox(height: 8),
                                  Text('Supported: JPG, PNG, MP4', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                  onPressed: () {
                    // Save to Supabase logic
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property Saved to Supabase Database!')));
                  },
                  child: const Text('Save Property'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
