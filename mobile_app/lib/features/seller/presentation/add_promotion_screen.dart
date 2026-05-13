import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import '../data/seller_promotions_provider.dart';
import './manage_inventory_screen.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../../../models/promotion.dart';
import '../../../models/listing.dart';

class AddPromotionScreen extends ConsumerStatefulWidget {
  final Promotion? promotion;
  const AddPromotionScreen({super.key, this.promotion});

  @override
  ConsumerState<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends ConsumerState<AddPromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  
  XFile? _pickedImage;
  String? _currentImageUrl;
  String? _selectedListingId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.promotion?.title);
    _subtitleController = TextEditingController(text: widget.promotion?.subtitle);
    _currentImageUrl = widget.promotion?.imageUrl;
    _selectedListingId = widget.promotion?.listingId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null && _currentImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an image', style: TextStyle(fontSize: 14.sp))));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(sellerPromotionsProvider.notifier);
      
      String imageUrl = _currentImageUrl ?? '';
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        imageUrl = await notifier.uploadImage(bytes);
      }

      if (widget.promotion == null) {
        await notifier.addPromotion(
          title: _titleController.text,
          subtitle: _subtitleController.text,
          imageUrl: imageUrl,
          listingId: _selectedListingId,
        );
      } else {
        await notifier.updatePromotion(
          id: widget.promotion!.id,
          title: _titleController.text,
          subtitle: _subtitleController.text,
          imageUrl: imageUrl,
          isActive: widget.promotion!.isActive, 
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: TextStyle(fontSize: 14.sp))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(myListingsProvider);
    final isEditing = widget.promotion != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Ad' : 'Create New Ad', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              SizedBox(height: 10.h),
              Text('Tap to upload an ad banner (Recommended size: 1000x400)', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
              SizedBox(height: 30.h),

              _buildTextField(_titleController, 'Ad Title', 'e.g., Best Deals on Tires', Icons.title),
              SizedBox(height: 20.h),
              _buildTextField(_subtitleController, 'Subtitle (Optional)', 'e.g., Up to 50% Off', Icons.subtitles, required: false),
              SizedBox(height: 30.h),
              
              Text('Link to Listing', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.h),
              listingsAsync.when(
                data: (listings) => DropdownButtonFormField<String>(
                  value: _selectedListingId,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.link, color: AppTheme.accentColor, size: 24.r),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                  hint: Text('Select a listing to promote', style: TextStyle(fontSize: 14.sp)),
                  items: [
                    DropdownMenuItem(value: null, child: Text('No specific listing', style: TextStyle(fontSize: 14.sp))),
                    ...listings.map((l) => DropdownMenuItem(
                      value: l.id,
                      child: Text(l.title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp)),
                    )),
                  ],
                  onChanged: (val) => setState(() => _selectedListingId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (err, st) => Text('Error loading listings: $err', style: TextStyle(fontSize: 14.sp)),
              ),
              
              SizedBox(height: 40.h),
              SizedBox(
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: _isLoading 
                    ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEditing ? 'UPDATE AD' : 'PUBLISH AD', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_pickedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: Image.network(_pickedImage!.path, fit: BoxFit.cover, width: double.infinity),
      );
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: CachedNetworkImage(
          imageUrl: _currentImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 40.r, color: Colors.grey),
          SizedBox(height: 8.h),
          Text('Select Ad Banner', style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
        ],
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {bool required = true}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp),
        hintStyle: TextStyle(fontSize: 14.sp),
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.accentColor, size: 24.r),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
      validator: required ? (val) => (val == null || val.isEmpty) ? 'Required' : null : null,
    );
  }
}
