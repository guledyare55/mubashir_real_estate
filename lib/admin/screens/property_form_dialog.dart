import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/models/category.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/property.dart';
import '../../core/models/owner.dart';
import '../../core/models/employee.dart';
import '../../core/models/agency_settings.dart';

class PropertyFormDialog extends StatefulWidget {
  final Property? property;
  final bool isReadOnly;
  const PropertyFormDialog({super.key, this.property, this.isReadOnly = false});

  @override
  State<PropertyFormDialog> createState() => _PropertyFormDialogState();
}

class _PropertyFormDialogState extends State<PropertyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _bedsController = TextEditingController(text: '0');
  final _bathsController = TextEditingController(text: '0');
  final _sizeController = TextEditingController(text: '0');
  final _locationController = TextEditingController();
  
  final SupabaseService _supabaseService = SupabaseService();
  
  String _type = 'Sale';
  String _status = 'Available';
  String _currency = r'$';
  
  // Media State
  final List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  // Owner & Agent State
  late Future<List<Owner>> _ownersFuture;
  late Future<List<Employee>> _agentsFuture;
  late Future<List<PropertyCategory>> _categoriesFuture;
  
  String? _selectedOwnerId;
  String? _selectedAgentId;
  String? _selectedCategory;
  
  // High-fidelity image tracking
  List<String> _existingUrls = [];
  final List<String> _urlsToDelete = [];
  bool _showImageError = false;

  @override
  void initState() {
    super.initState();
    _ownersFuture = _supabaseService.fetchOwners();
    _agentsFuture = _supabaseService.fetchEmployees();
    _categoriesFuture = _supabaseService.fetchCategories();
    
    // Fetch default currency from settings
    _supabaseService.fetchAgencySettings().then((settings) {
      if (mounted && widget.property == null) {
        setState(() {
          _currency = settings.currencySymbol;
        });
      }
    });

    if (widget.property != null) {
      final p = widget.property!;
      _titleController.text = p.title;
      _priceController.text = p.price.toString();
      _descController.text = p.description;
      _bedsController.text = p.beds.toString();
      _bathsController.text = p.baths.toString();
      _sizeController.text = p.size.toString();
      _type = p.type;
      _status = p.status == 'Rent' ? 'Rented' : (p.status == 'Sale' ? 'Sold' : p.status);
      _selectedOwnerId = p.ownerId;
      _selectedAgentId = p.agentId;
      _selectedCategory = p.categoryName; 
      _existingUrls = List.from(p.galleryUrls);
      _currency = p.currency;
      _locationController.text = p.location ?? '';
    }
  }

  void _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true, 
      type: FileType.image,
    );
    
    if (result != null) {
      setState(() {
        _showImageError = false;
        // Only add files that aren't already in the list (by path)
        for (var file in result.files) {
          if (!_selectedFiles.any((element) => element.path == file.path)) {
            _selectedFiles.add(file);
          }
        }
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _removeExisting(int index) {
    setState(() {
      final url = _existingUrls.removeAt(index);
      _urlsToDelete.add(url);
    });
  }

  Future<void> _simulateUpload() async {
    if (_selectedFiles.isEmpty) return;
    
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Simulate progress
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _uploadProgress = i / 10;
      });
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1000,
        height: 800,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isReadOnly 
                    ? 'View Property Details' 
                    : (widget.property != null ? 'Edit Property' : 'Add New Property'), 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                ),
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
                      flex: 3, // Increased from 2 to prevent overflow in field rows
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              readOnly: widget.isReadOnly,
                              decoration: const InputDecoration(labelText: 'Property Title', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _locationController,
                              readOnly: widget.isReadOnly,
                              decoration: const InputDecoration(
                                labelText: 'Location / Neighborhood', 
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on_rounded),
                                hintText: 'e.g. Bole, Addis Ababa'
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                child: TextFormField(
                                  controller: _priceController,
                                  readOnly: widget.isReadOnly,
                                  decoration: InputDecoration(
                                    labelText: 'Price', 
                                    prefixText: '$_currency ', 
                                    border: const OutlineInputBorder(),
                                    suffixIcon: widget.isReadOnly ? null : DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _currency,
                                        items: [r'$', 'ETB', '€', '£', 'KES', 'UGX'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                        onChanged: (v) => setState(() => _currency = v!),
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    value: _type,
                                    decoration: const InputDecoration(labelText: 'Listing Type', border: OutlineInputBorder()),
                                    items: ['Sale', 'Rent'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                    onChanged: widget.isReadOnly ? null : (v) => setState(() => _type = v!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: FutureBuilder<List<PropertyCategory>>(
                                    future: _categoriesFuture,
                                    builder: (context, snapshot) {
                                      final cats = snapshot.data ?? [];
                                      // Ensure current value is in the list to prevent assertion error
                                      final items = cats.map((c) => DropdownMenuItem<String?>(value: c.name, child: Text(c.name))).toList();
                                      final effectiveValue = items.any((i) => i.value == _selectedCategory) ? _selectedCategory : null;
                                      
                                      return DropdownButtonFormField<String?>(
                                        value: effectiveValue,
                                        isExpanded: true,
                                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_rounded)),
                                        items: items,
                                        onChanged: widget.isReadOnly ? null : (v) => setState(() => _selectedCategory = v),
                                        hint: const Text('Select Category'),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descController,
                              readOnly: widget.isReadOnly,
                              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(height: 16),
                            const Text('2. Ownership & Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FutureBuilder<List<Owner>>(
                                    future: _ownersFuture,
                                    builder: (context, snapshot) {
                                      final owners = snapshot.data ?? [];
                                      final isLoading = snapshot.connectionState == ConnectionState.waiting;
                                      
                                      final items = [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Unassigned / None'),
                                          ),
                                          ...owners.map((o) => DropdownMenuItem<String?>(
                                            value: o.id, 
                                            child: Text(o.name, overflow: TextOverflow.ellipsis),
                                          )),
                                      ];
                                      final effectiveValue = items.any((i) => i.value == _selectedOwnerId) ? _selectedOwnerId : null;

                                      return DropdownButtonFormField<String?>(
                                        value: effectiveValue,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Property Owner',
                                          hintText: 'Select Owner (Optional)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.person_pin_rounded),
                                        ),
                                        items: items,
                                        onChanged: widget.isReadOnly ? null : (v) => setState(() => _selectedOwnerId = v),
                                        hint: Text(isLoading ? 'Fetching Owners...' : 'Select Owner'),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FutureBuilder<List<Employee>>(
                                    future: _agentsFuture,
                                    builder: (context, snapshot) {
                                      final agents = snapshot.data ?? [];
                                      final isLoading = snapshot.connectionState == ConnectionState.waiting;
                                      
                                      final items = [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Self Managed / None'),
                                          ),
                                          ...agents.map((a) => DropdownMenuItem<String?>(
                                            value: a.id, 
                                            child: Text(a.name, overflow: TextOverflow.ellipsis),
                                          )),
                                      ];
                                      final effectiveValue = items.any((i) => i.value == _selectedAgentId) ? _selectedAgentId : null;

                                      return DropdownButtonFormField<String?>(
                                        value: effectiveValue,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Assign Agent',
                                          hintText: 'Select Agent (Optional)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.badge_rounded),
                                        ),
                                        items: items,
                                        onChanged: widget.isReadOnly ? null : (v) => setState(() => _selectedAgentId = v),
                                        hint: Text(isLoading ? 'Fetching Staff...' : 'Select Agent'),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(height: 12),
                            const Text('3. Availability & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(labelText: 'Current Availability Status', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              items: ['Available', 'Under Offer', 'Sold', 'Rented'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: widget.isReadOnly ? null : (v) => setState(() => _status = v!),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bedsController,
                                    readOnly: widget.isReadOnly,
                                    decoration: const InputDecoration(labelText: 'Beds', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _bathsController,
                                    readOnly: widget.isReadOnly,
                                    decoration: const InputDecoration(labelText: 'Baths', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sizeController,
                                    readOnly: widget.isReadOnly,
                                    decoration: const InputDecoration(labelText: 'Size (m²)', border: OutlineInputBorder()),
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
                      flex: 2, // Increased flex to provide more horizontal room
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Property Media', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 16),
                          if (_isUploading) ...[
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(value: _uploadProgress, strokeWidth: 8, color: const Color(0xFF1E3A8A)),
                                  const SizedBox(height: 16),
                                  Text('${(_uploadProgress * 100).toInt()}% Uploaded to R2...', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ] else if (_selectedFiles.isEmpty && _existingUrls.isEmpty) ...[
                            _buildUploadPlaceholder()
                          ] else ...[
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _existingUrls.length + _selectedFiles.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _existingUrls.length + _selectedFiles.length) {
                                    return widget.isReadOnly ? const SizedBox.shrink() : _buildAddMoreButton();
                                  }
                                  
                                  if (index < _existingUrls.length) {
                                    return _buildExistingPreview(index);
                                  }
                                  
                                  return _buildFilePreview(index - _existingUrls.length);
                                },
                              ),
                            ),
                          ],
                          if (_showImageError) ...[
                            const SizedBox(height: 12),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: 1.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                                    SizedBox(width: 8),
                                    Text('At least one property image is required', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(widget.isReadOnly ? 'Close' : 'Cancel')),
                if (!widget.isReadOnly) ...[
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                    onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // 1. Minimum Image Validation
                      if (_selectedFiles.isEmpty && _existingUrls.isEmpty) {
                        setState(() => _showImageError = true);
                        return;
                      }
                      setState(() => _showImageError = false);

                      setState(() => _isUploading = true);
                      
                      List<String> uploadedUrls = [];
                      try {
                        for (int i = 0; i < _selectedFiles.length; i++) {
                          final file = _selectedFiles[i];
                          final bytes = await File(file.path!).readAsBytes();
                          final url = await _supabaseService.uploadPropertyImage(bytes, file.name);
                          uploadedUrls.add(url);
                          
                          setState(() {
                            _uploadProgress = (i + 1) / _selectedFiles.length;
                          });
                        }

                        final updatedGallery = [..._existingUrls, ...uploadedUrls];

                          // Create the property object with real data
                          final propertyToSave = Property(
                            id: widget.property?.id ?? '', // Preserve ID if editing
                            title: _titleController.text,
                            description: _descController.text,
                            price: double.tryParse(_priceController.text) ?? 0.0,
                            type: _type, 
                            categoryName: _selectedCategory, 
                            beds: int.tryParse(_bedsController.text) ?? 0,
                            baths: int.tryParse(_bathsController.text) ?? 0,
                            size: double.tryParse(_sizeController.text) ?? 0.0,
                            status: _status,
                          mainImageUrl: updatedGallery.isNotEmpty ? updatedGallery.first : '',
                            galleryUrls: updatedGallery,
                            ownerId: _selectedOwnerId,
                            agentId: _selectedAgentId,
                            currency: _currency,
                            location: _locationController.text.isEmpty ? null : _locationController.text,
                          );

                        if (widget.property != null) {
                          await _supabaseService.updateProperty(propertyToSave);
                        } else {
                          await _supabaseService.addProperty(propertyToSave);
                        }
                        // 3. Purge orphans from bucket after successful DB update
                        int deletedCount = 0;
                        if (_urlsToDelete.isNotEmpty) {
                          try {
                            deletedCount = await _supabaseService.deleteImages(_urlsToDelete);
                          } catch (e) {
                             if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Storage Cleanup Failed: $e'), backgroundColor: Colors.orange),
                              );
                            }
                            // We don't return here because the DB update was already successful
                          }
                        }

                        if (mounted) {
                          Navigator.of(context).pop(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Saved! ${uploadedUrls.length} new uploaded, $deletedCount old purged.'))
                          );
                        }
                      } catch (e) {
                         if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving property: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => _isUploading = false);
                      }
                    }
                  },
                    child: const Text('Save Property'),
                  ),
                ],
              ]
            )
          ],
        ),
      ),
    );
  }

  Widget _buildExistingPreview(int index) {
    final url = _existingUrls[index];
    final isMain = index == 0;
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isMain ? const Color(0xFF1E3A8A) : Colors.transparent, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              url,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (isMain)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(4)),
              child: const Text('MAIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        if (!widget.isReadOnly)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removeExisting(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
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
            Text('Supported: JPG, PNG', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(int index) {
    final file = _selectedFiles[index];
    final isMain = index == 0;
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isMain ? const Color(0xFF1E3A8A) : Colors.transparent, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(file.path!),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (isMain)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(4)),
              child: const Text('MAIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removeFile(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: _pickFiles,
        borderRadius: BorderRadius.circular(8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
            SizedBox(height: 4),
            Text('Add More', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
