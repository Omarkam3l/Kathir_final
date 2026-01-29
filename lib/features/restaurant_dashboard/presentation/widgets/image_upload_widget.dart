import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_colors.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(File?, List<int>?) onImageSelected;
  final bool isDark;

  const ImageUploadWidget({
    this.initialImageUrl,
    required this.onImageSelected,
    required this.isDark,
    super.key,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _imageFile;
  List<int>? _imageBytes;
  String? _imageUrl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          _imageBytes = await pickedFile.readAsBytes();
          setState(() => _imageUrl = null);
          widget.onImageSelected(null, _imageBytes);
        } else {
          _imageFile = File(pickedFile.path);
          setState(() => _imageUrl = null);
          widget.onImageSelected(_imageFile, null);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.4),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primaryGreen.withValues(alpha: 0.05),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Show selected image
    if (_imageFile != null && !kIsWeb) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _imageFile!,
              fit: BoxFit.cover,
            ),
          ),
          _buildOverlay(),
        ],
      );
    }

    // Show selected image bytes (web)
    if (_imageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
            ),
          ),
          _buildOverlay(),
        ],
      );
    }

    // Show existing URL
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            ),
          ),
          _buildOverlay(),
        ],
      );
    }

    // Show placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfaceDark : Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.add_a_photo,
            size: 32,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to add meal photo',
          style: TextStyle(
            color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Max 5MB • JPEG, PNG, WebP',
          style: TextStyle(
            color: widget.isDark ? Colors.grey[500] : Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.3),
      ),
      child: const Center(
        child: Icon(
          Icons.edit,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
