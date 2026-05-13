import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../../../models/listing.dart';
import '../../common/data/ai_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  final Listing? listing; // If provided, we differ to edit mode

  const AddListingScreen({super.key, this.listing});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Fields
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  
  String _category = 'Body';
  String _condition = 'Used';
  List<String> _imageUrls = []; 
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _titleController = TextEditingController(text: l?.title);
    _descriptionController = TextEditingController(text: l?.description);
    _priceController = TextEditingController(text: l?.price.toString());
    _makeController = TextEditingController(text: l?.vehicleMake);
    _modelController = TextEditingController(text: l?.vehicleModel);
    
    if (l != null) {
      _category = l.category;
      _condition = l.condition;
      _imageUrls = l.images;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileExt = image.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.$fileExt';
      final path = 'listings/$fileName';

      final bytes = await image.readAsBytes();
      await Supabase.instance.client.storage.from('listings').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final publicUrl = Supabase.instance.client.storage.from('listings').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e', style: TextStyle(fontSize: 14.sp))));
      }
      return null;
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Require image only for NEW listings if no existing images
    if (_selectedImage == null && _imageUrls.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an image', style: TextStyle(fontSize: 14.sp))));
       return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // 1. Upload New Image if selected
      if (_selectedImage != null) {
        final imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl != null) {
          _imageUrls = [imageUrl];

          // AI: Analyze Image for Category Suggestion
          try {
             final aiRepo = ref.read(aiRepositoryProvider);
             final imageAnalysis = await aiRepo.analyzeImage(imageUrl);
             if (imageAnalysis.containsKey('category')) {
               final suggestedCategory = imageAnalysis['category'];
               if (mounted) {
                 setState(() {
                   _category = suggestedCategory;
                 });
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('AI Suggested Category: $suggestedCategory', style: TextStyle(fontSize: 14.sp)), backgroundColor: Colors.blue),
                 );
               }
             }
          } catch (e) {
            print('AI Image Analysis Failed: $e');
          }
        }
      }

      // 2. Prepare Data
      final listingData = {
        'seller_id': user.id,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category': _category,
        'condition': _condition,
        'vehicle_make': _makeController.text,
        'vehicle_model': _modelController.text,
        'images': _imageUrls, 
        'status': 'pending', 
      };

      // AI: Fraud Detection Check
      if (widget.listing == null) {
         final aiRepo = ref.read(aiRepositoryProvider);
         final aiPayload = {
           'seller_id': user.id,
           'title': _titleController.text,
           'description': _descriptionController.text,
           'price': double.parse(_priceController.text),
           'category': _category,
           'image_url': _imageUrls.isNotEmpty ? _imageUrls.first : '',
           'vehicle_model': _modelController.text,
         };
         
         final fraudResult = await aiRepo.analyzeListing(aiPayload);
         if (fraudResult['status'] == 'rejected') {
            if (mounted) {
              setState(() => _isLoading = false);
              _showFraudAlert(context, fraudResult['details']);
            }
            return; 
         } 
      }

      if (widget.listing != null) {
        await Supabase.instance.client
            .from('listings')
            .update(listingData)
            .eq('id', widget.listing!.id);
            
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Listing updated and sent for approval!', style: TextStyle(fontSize: 14.sp)), backgroundColor: Colors.green),
          );
          context.pop(); 
        }
      } else {
        await Supabase.instance.client
            .from('listings')
            .insert(listingData); 

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Listing submitted for approval!', style: TextStyle(fontSize: 14.sp)), backgroundColor: Colors.green),
          );
          context.pop(); 
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: TextStyle(fontSize: 14.sp)), backgroundColor: Colors.red),
        );
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.listing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Listing' : 'Add New Listing', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)), 
        backgroundColor: AppTheme.accentColor, 
        foregroundColor: Colors.white
      ),
      body: SafeArea( 
        child: SingleChildScrollView( 
          padding: EdgeInsets.all(16.0.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_titleController, 'Title', 'e.g. Toyota Corolla Bumper'),
                SizedBox(height: 12.h),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTextField(_priceController, 'Price (LKR)', '15000', isNumber: true)),
                    SizedBox(width: 12.w),
                    Expanded(child: _buildDropdown('Condition', ['New', 'Used', 'Reconditioned'], _condition, (v) => setState(() => _condition = v!))),
                  ],
                ),
                SizedBox(height: 12.h),

                 Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTextField(_makeController, 'Make', 'Toyota')),
                    SizedBox(width: 12.w),
                    Expanded(child: _buildTextField(_modelController, 'Model', 'Corolla')),
                  ],
                ),
                SizedBox(height: 12.h),

                _buildDropdown('Category', ['Engine', 'Body', 'Electrical', 'Suspension', 'Interior', 'Accessories'], _category, (v) => setState(() => _category = v!)),
                SizedBox(height: 12.h),

                _buildTextField(_descriptionController, 'Description', 'Describe the item condition, compatibility...', maxLines: 3),
                SizedBox(height: 20.h),

                // Image Picker UI
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    clipBehavior: Clip.hardEdge, 
                    child: _selectedImage != null 
                      ? (kIsWeb 
                          ? Image.network(_selectedImage!.path, fit: BoxFit.cover, width: double.infinity) 
                          : Image.file(File(_selectedImage!.path), fit: BoxFit.cover, width: double.infinity))
                      : (_imageUrls.isNotEmpty 
                          ? CachedNetworkImage(imageUrl: _imageUrls.first, fit: BoxFit.cover, width: double.infinity)
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40.r, color: Colors.grey),
                                  Text('Tap to upload photo', style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
                                ],
                              ),
                            )),
                  ),
                ),
                SizedBox(height: 24.h),

                SizedBox(
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitListing,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                    child: _isLoading ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEditing ? 'Update Listing' : 'Submit Listing', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp),
        hintStyle: TextStyle(fontSize: 14.sp),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  void _showFraudAlert(BuildContext context, Map<String, dynamic> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Listing Rejected', style: TextStyle(color: Colors.red, fontSize: 18.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your listing was flagged by our safety system and cannot be posted.', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 10.h),
            if ((details['price_risk'] as num) > 0.5)
              Text('• Price is suspiciously low/high for this category.', style: TextStyle(fontSize: 13.sp)),
            if ((details['text_risk'] as num) > 0.5)
              Text('• Title or description contains suspicious keywords or excessive capitalization.', style: TextStyle(fontSize: 13.sp)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('OK', style: TextStyle(fontSize: 14.sp))),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: TextStyle(fontSize: 14.sp, color: Colors.black),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
