import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../data/seller_profile_provider.dart';

class EditSellerProfileScreen extends ConsumerStatefulWidget {
  const EditSellerProfileScreen({super.key});

  @override
  ConsumerState<EditSellerProfileScreen> createState() => _EditSellerProfileScreenState();
}

class _EditSellerProfileScreenState extends ConsumerState<EditSellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _shopNameController;
  late TextEditingController _shopAddressController;
  String? _selectedDistrict;

  final List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo',
    'Galle', 'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara',
    'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar',
    'Matale', 'Matara', 'Moneragala', 'Mullaitivu', 'Nuwara Eliya',
    'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya'
  ];
  
  XFile? _selectedImage; 
  String? _currentAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _shopNameController = TextEditingController();
    _shopAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(sellerProfileControllerProvider.notifier).updateProfile(
        fullName: _nameController.text.trim(),
        shopName: _shopNameController.text.trim(),
        shopAddress: '${_selectedDistrict ?? ""}, ${_shopAddressController.text.trim()}',
        newAvatarFile: _selectedImage,
      );
      
      ref.invalidate(sellerProfileProvider); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile Updated!', style: TextStyle(fontSize: 14.sp))));
        context.pop();
      }
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
    final profileAsync = ref.watch(sellerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Shop Details', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.check, size: 24.r),
            onPressed: _isLoading ? null : _saveProfile,
          )
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return Center(child: Text('User not found', style: TextStyle(fontSize: 14.sp)));
          
          if (_nameController.text.isEmpty && _shopNameController.text.isEmpty) {
             _nameController.text = profile.fullName;
             _shopNameController.text = profile.shopName ?? '';
             _shopAddressController.text = profile.shopAddress ?? '';
             _currentAvatarUrl = profile.avatarUrl;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.0.r),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Avatar Picker
                   Center(
                     child: GestureDetector(
                       onTap: _pickImage,
                       child: Stack(
                         children: [
                           if (_selectedImage != null)
                             CircleAvatar(
                               radius: 60.r,
                               backgroundColor: Colors.grey[300],
                               backgroundImage: kIsWeb 
                                   ? NetworkImage(_selectedImage!.path) 
                                   : FileImage(File(_selectedImage!.path)) as ImageProvider,
                             )
                           else
                             CircleAvatar(
                               radius: 60.r,
                               backgroundColor: Colors.grey[300],
                               backgroundImage: _currentAvatarUrl != null ? CachedNetworkImageProvider(_currentAvatarUrl!) : null,
                               child: (_currentAvatarUrl == null)
                                   ? Icon(Icons.store, size: 60.r, color: Colors.grey)
                                   : null,
                             ),
                   
                           Positioned(
                             bottom: 0,
                             right: 0,
                             child: Container(
                               padding: EdgeInsets.all(8.r),
                               decoration: const BoxDecoration(
                                 color: AppTheme.accentColor,
                                 shape: BoxShape.circle,
                               ),
                               child: Icon(Icons.camera_alt, color: Colors.white, size: 20.r),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                   SizedBox(height: 32.h),
                   
                   _buildTextField(_nameController, 'Your Name', 'Enter your full name'),
                   SizedBox(height: 16.h),
                   
                   _buildTextField(_shopNameController, 'Shop Name', 'Enter your shop name'),
                   SizedBox(height: 16.h),
                   
                   // District Dropdown
                   DropdownButtonFormField<String>(
                     value: _selectedDistrict,
                     decoration: InputDecoration(
                       labelText: 'District',
                       labelStyle: TextStyle(fontSize: 14.sp),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                       contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                     ),
                     items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 14.sp)))).toList(),
                     onChanged: (val) => setState(() => _selectedDistrict = val),
                     validator: (v) => v == null ? 'Please select a district' : null,
                   ),
                   SizedBox(height: 16.h),
                   
                   _buildTextField(_shopAddressController, 'Address Details', 'Enter street, city, etc.', maxLines: 3),
                   
                   if (_isLoading)
                     Padding(
                       padding: EdgeInsets.only(top: 20.0.h),
                       child: const Center(child: CircularProgressIndicator()),
                     ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(fontSize: 14.sp))),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp),
        hintStyle: TextStyle(fontSize: 14.sp),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}
