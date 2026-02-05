import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/auth_logger.dart';
import '../../../../core/services/ai_meal_service.dart';
import '../widgets/image_upload_widget.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  late final AiMealService _aiService;
  
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  
  // Form state
  String _category = 'Meals';
  DateTime? _expiryDate;
  DateTime? _pickupDeadline;
  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _isAiProcessing = false;

  // Categories must match database constraint exactly
  final List<String> _categories = [
    'Meals',
    'Bakery',
    'Meat & Poultry',
    'Seafood',
    'Vegetables',
    'Desserts',
    'Groceries',
  ];

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('⚠️ GEMINI_API_KEY not found in .env - AI features will be disabled');
      debugPrint('Please add GEMINI_API_KEY to your .env file and restart the app');
    } else {
      debugPrint('✅ GEMINI_API_KEY loaded successfully');
    }
    _aiService = AiMealService(apiKey: apiKey ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _fillWithAi() async {
    if (_imageFile == null && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isAiProcessing = true);

    try {
      AuthLogger.info('ai.fill.start');

      // Detect mime type from file extension
      String mimeType = 'image/jpeg'; // default
      if (_imageFile != null) {
        final path = _imageFile!.path.toLowerCase();
        if (path.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (path.endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (path.endsWith('.webp')) {
          mimeType = 'image/webp';
        } else if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        }
      }

      AiMealData aiData;
      
      if (_imageBytes != null) {
        // Use bytes for web or when available
        aiData = await _aiService.extractMealInfoFromBytes(
          _imageBytes!,
          mimeType: mimeType,
        );
      } else if (_imageFile != null) {
        // Read file bytes for mobile
        final bytes = await _imageFile!.readAsBytes();
        aiData = await _aiService.extractMealInfoFromBytes(
          Uint8List.fromList(bytes),
          mimeType: mimeType,
        );
      } else {
        throw Exception('No image data available');
      }

      // Fill form with AI data
      setState(() {
        _titleController.text = aiData.mealTitle;
        _descriptionController.text = aiData.description;
        
        // Map category slug to display name
        _category = _mapCategorySlugToDisplay(aiData.categorySlug);
        
        _originalPriceController.text = 
            aiData.priceSuggestions.originalPriceEgp.toStringAsFixed(2);
        _discountedPriceController.text = 
            aiData.priceSuggestions.discountedPriceEgp.toStringAsFixed(2);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✨ Form filled with AI!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: Title ${(aiData.confidence.mealTitle * 100).toInt()}%, '
                  'Category ${(aiData.confidence.categorySlug * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      AuthLogger.info('ai.fill.success');
    } catch (e, stackTrace) {
      AuthLogger.errorLog('ai.fill.failed', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI extraction failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiProcessing = false);
    }
  }

  String _mapCategorySlugToDisplay(String slug) {
    // Map from AI response categories to display categories
    final mapping = {
      'meals': 'Meals',
      'bakery': 'Bakery',
      'meat_poultry': 'Meat & Poultry',
      'seafood': 'Seafood',
      'vegetables': 'Vegetables',
      'desserts': 'Desserts',
      'groceries': 'Groceries',
    };
    
    return mapping[slug.toLowerCase()] ?? 'Meals';
  }

  Future<String?> _uploadImage() async {
    try {
      final restaurantId = _supabase.auth.currentUser?.id;
      if (restaurantId == null) throw Exception('Not authenticated');

      // Validate file size
      int fileSize = 0;
      if (kIsWeb && _imageBytes != null) {
        fileSize = _imageBytes!.length;
      } else if (_imageFile != null) {
        fileSize = await _imageFile!.length();
      }

      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image size must be less than 5MB');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final mealId = const Uuid().v4();
      final filename = 'meal_${mealId}_$timestamp.jpg';
      final path = '$restaurantId/$filename';

      AuthLogger.info('meal.image.upload.start', ctx: {
        'restaurantId': restaurantId,
        'filename': filename,
        'fileSize': fileSize,
      });

      // Upload to Supabase
      if (kIsWeb && _imageBytes != null) {
        await _supabase.storage.from('meal-images').uploadBinary(path, _imageBytes!);
      } else if (_imageFile != null) {
        await _supabase.storage.from('meal-images').upload(path, _imageFile!);
      }

      // Get public URL
      final url = _supabase.storage.from('meal-images').getPublicUrl(path);

      AuthLogger.info('meal.image.upload.success', ctx: {
        'url': url,
      });

      return url;
    } catch (e, stackTrace) {
      AuthLogger.errorLog('meal.image.upload.failed',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a meal image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select expiry date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image
      final imageUrl = await _uploadImage();
      if (imageUrl == null) throw Exception('Failed to upload image');

      // Get restaurant ID
      final restaurantId = _supabase.auth.currentUser?.id;
      if (restaurantId == null) throw Exception('Not authenticated');

      // Save meal
      final mealResponse = await _supabase.from('meals').insert({
        'restaurant_id': restaurantId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'image_url': imageUrl,
        'original_price': double.parse(_originalPriceController.text),
        'discounted_price': double.parse(_discountedPriceController.text),
        'quantity_available': int.parse(_quantityController.text),
        'expiry_date': _expiryDate!.toIso8601String(),
        'pickup_deadline': _pickupDeadline?.toIso8601String(),
        'status': 'active',
      }).select().single();

      final mealId = mealResponse['id'];

      AuthLogger.info('meal.created', ctx: {
        'title': _titleController.text.trim(),
        'category': _category,
        'mealId': mealId,
      });

      // Create notifications for subscribed users
      try {
        final notificationResult = await _supabase.rpc('create_meal_notifications', params: {
          'p_meal_id': mealId,
          'p_category': _category,
          'p_restaurant_id': restaurantId,
        });
        
        final notificationsCreated = notificationResult[0]['notifications_created'] as int;
        AuthLogger.info('notifications.created', ctx: {
          'count': notificationsCreated,
          'category': _category,
        });
        
        debugPrint('✅ Created $notificationsCreated notifications for category: $_category');
      } catch (e) {
        AuthLogger.errorLog('notifications.create.failed', error: e);
        debugPrint('⚠️ Failed to create notifications: $e');
        // Don't fail the meal creation if notifications fail
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal published successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AuthLogger.errorLog('meal.create.failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Add New Meal'),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image upload
            ImageUploadWidget(
              isDark: isDark,
              showAiButton: true,
              onFillWithAi: _isAiProcessing ? null : _fillWithAi,
              onImageSelected: (file, bytes) {
                setState(() {
                  _imageFile = file;
                  _imageBytes = bytes;
                });
              },
            ),
            if (_isAiProcessing) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI is analyzing your meal image...',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Title
            _buildLabel('Meal Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('e.g. Grilled Chicken Salad', isDark),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 3) return 'Title must be at least 3 characters';
                if (v.trim().length > 100) return 'Title must be less than 100 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Description
            _buildLabel('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 500,
              decoration: _inputDecoration('Describe ingredients, allergens, etc.', isDark),
            ),
            const SizedBox(height: 20),

            // Category
            _buildLabel('Category *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) => _buildCategoryChip(cat)).toList(),
            ),
            const SizedBox(height: 20),

            // Prices
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Original Price (EGP) *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _originalPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('0.00', isDark),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final price = double.tryParse(v);
                          if (price == null || price <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Discounted Price (EGP) *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _discountedPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('0.00', isDark),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final discounted = double.tryParse(v);
                          final original = double.tryParse(_originalPriceController.text);
                          if (discounted == null || discounted <= 0) return 'Must be > 0';
                          if (original != null && discounted > original) {
                            return 'Must be ≤ original';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quantity
            _buildLabel('Quantity Available *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Number of portions', isDark),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final qty = int.tryParse(v);
                if (qty == null || qty < 1) return 'Must be ≥ 1';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Expiry Date
            _buildLabel('Expiry Date & Time *'),
            const SizedBox(height: 8),
            _buildDateTimePicker(
              label: _expiryDate == null
                  ? 'Select expiry date & time'
                  : _formatDateTime(_expiryDate!),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _expiryDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Pickup Deadline
            _buildLabel('Pickup Deadline (Optional)'),
            const SizedBox(height: 8),
            _buildDateTimePicker(
              label: _pickupDeadline == null
                  ? 'Select pickup deadline'
                  : _formatDateTime(_pickupDeadline!),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _pickupDeadline = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Publish Meal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.check),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _category == category;
    return FilterChip(
      selected: isSelected,
      label: Text(category),
      onSelected: (_) => setState(() => _category = category),
      selectedColor: AppColors.primaryGreen,
      checkmarkColor: Colors.black,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryGreen : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: label.contains('Select')
                      ? (isDark ? Colors.grey[500] : Colors.grey[400])
                      : null,
                ),
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
