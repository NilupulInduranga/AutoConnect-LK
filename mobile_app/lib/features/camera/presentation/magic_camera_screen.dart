import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'object_detection_service.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';

class MagicCameraScreen extends ConsumerStatefulWidget {
  const MagicCameraScreen({super.key});

  @override
  ConsumerState<MagicCameraScreen> createState() => _MagicCameraScreenState();
}

class _MagicCameraScreenState extends ConsumerState<MagicCameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  String? _detectedLabel;
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDetecting) return;

    setState(() => _isDetecting = true);

    try {
      final image = await _controller!.takePicture();
      final results = await ref.read(objectDetectionServiceProvider).detectObject(File(image.path));
      
      if (results.isNotEmpty) {
        setState(() {
          _detectedLabel = results.first['label'];
        });
        if (mounted) _showResultsDialog(results);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: TextStyle(fontSize: 14.sp))));
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  void _showResultsDialog(List<Map<String, dynamic>> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5.r)),
            ),
            SizedBox(height: 24.h),
            Icon(Icons.verified, color: AppTheme.primaryColor, size: 64.r),
            SizedBox(height: 16.h),
            Text(
              'Part Identified!',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                _detectedLabel ?? "General Spare Part",
                style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18.sp),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, _detectedLabel);
                },
                child: Text('Find in Marketplace', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          
          // Outer Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280.w,
                    height: 280.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scanner Border and Animation
          Center(
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.w),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Stack(
                children: [
                  // Corner accents
                  _buildCorner(top: 0, left: 0, isTop: true, isLeft: true),
                  _buildCorner(top: 0, right: 0, isTop: true, isRight: true),
                  _buildCorner(bottom: 0, left: 0, isBottom: true, isLeft: true),
                  _buildCorner(bottom: 0, right: 0, isBottom: true, isRight: true),
                  
                  AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      return Positioned(
                        top: _scannerController.value * 270.w,
                        left: 10.w,
                        right: 10.w,
                        child: Container(
                          height: 3.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0),
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.5), blurRadius: 10.r, spreadRadius: 2.r),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Top UI
          Positioned(
            top: 50.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 20.r),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 16.r),
                      SizedBox(width: 8.w),
                      Text('AutoLK Vision', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    ],
                  ),
                ),
                SizedBox(width: 40.w), // Spacing
              ],
            ),
          ),

          // Bottom Instruction
          Positioned(
            bottom: 150.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Text(
                  'Align part within the frame',
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                ),
              ),
            ),
          ),

          if (_isDetecting)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3.w),
                    SizedBox(height: 24.h),
                    Text('AutoLK Intelligence Processing...', style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
            
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 50.0.h),
              child: GestureDetector(
                onTap: _captureAndAnalyze,
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4.w),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(5.r),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.center_focus_strong, color: AppTheme.primaryColor, size: 32.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({double? top, double? left, double? right, double? bottom, bool isTop = false, bool isLeft = false, bool isRight = false, bool isBottom = false}) {
    return Positioned(
      top: top != null ? top.h : null,
      left: left != null ? left.w : null,
      right: right != null ? right.w : null,
      bottom: bottom != null ? bottom.h : null,
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? BorderSide(color: AppTheme.primaryColor, width: 4.w) : BorderSide.none,
            left: isLeft ? BorderSide(color: AppTheme.primaryColor, width: 4.w) : BorderSide.none,
            right: isRight ? BorderSide(color: AppTheme.primaryColor, width: 4.w) : BorderSide.none,
            bottom: isBottom ? BorderSide(color: AppTheme.primaryColor, width: 4.w) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
