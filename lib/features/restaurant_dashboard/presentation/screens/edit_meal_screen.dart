import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/restaurant_bottom_nav.dart';

/// Screen to edit an existing meal
class EditMealScreen extends StatefulWidget {
  final String mealId;

  const EditMealScreen({super.key, required this.mealId});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  // State
  String _category = 'meals';
  DateTime? _expiryDate;
  DateTime? _pickupDeadline;
  String? _imageUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMealData();
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

  Future<void> _loadMealData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('meals')
          .select()
          .eq('id', widget.mealId)
          .maybeSingle();

      if (response != null && mounted) {
        _titleController.text = response['title'] ?? '';
        _descriptionController.text = response['description'] ?? '';
        _originalPriceController.text = (response['original_price'] ?? 0).toString();
        _discountedPriceController.text = (response['discounted_price'] ?? 0).toString();
        _quantityController.text = (response['quantity_available'] ?? 0).toString();
        _category = response['category'] ?? 'meals';
        _imageUrl = response['image_url'];
        
        if (response['expiry_date'] != null) {
          _expiryDate = DateTime.parse(response['expiry_date']);
        }
        if (response['pickup_deadline'] != null) {
          _pickupDeadline = DateTime.parse(response['pickup_deadline']);
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meal: $e')),
        );
      }
    }
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _supabase.from('meals').update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'original_price': double.tryParse(_originalPriceController.text) ?? 0,
        'discounted_price': double.tryParse(_discountedPriceController.text) ?? 0,
        'quantity_available': int.tryParse(_quantityController.text) ?? 0,
        'expiry_date': _expiryDate?.toIso8601String(),
        'pickup_deadline': _pickupDeadline?.toIso8601String(),
        'image_url': _imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.mealId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/restaurant-dashboard/meals');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating meal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Edit Meal'),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Upload
                    ImageUploadWidget(
                      initialImageUrl: _imageUrl,
                      onImageUploaded: (url) => setState(() => _imageUrl = url),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    _buildLabel('Meal Title *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('e.g. Grilled Chicken Salad', isDark),
                      validator: (v) => v?.isEmpty == true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildLabel('Description'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration('Describe the meal...', isDark),
                    ),
                    const SizedBox(height: 20),

                    // Category
                    _buildLabel('Category *'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildCategoryChip('meals', 'Meals'),
                        _buildCategoryChip('bakery', 'Bakery'),
                        _buildCategoryChip('raw_ingredients', 'Raw Ingredients'),
                        _buildCategoryChip('vegan', 'Vegan'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Prices
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Original Price *'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _originalPriceController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('\$0.00', isDark),
                                validator: (v) => v?.isEmpty == true ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Discounted Price *'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _discountedPriceController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('\$0.00', isDark),
                                validator: (v) => v?.isEmpty == true ? 'Required' : null,
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
                      decoration: _inputDecoration('e.g. 10', isDark),
                      validator: (v) => v?.isEmpty == true ? 'Quantity is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Expiry Date
                    _buildLabel('Expiry Date *'),
                    const SizedBox(height: 8),
                    _buildDateTimePicker(
                      'Select expiry date',
                      _expiryDate,
                      (date) => setState(() => _expiryDate = date),
                      isDark,
                    ),
                    const SizedBox(height: 20),

                    // Pickup Deadline
                    _buildLabel('Pickup Deadline'),
                    const SizedBox(height: 8),
                    _buildDateTimePicker(
                      'Select pickup deadline',
                      _pickupDeadline,
                      (date) => setState(() => _pickupDeadline = date),
                      isDark,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveMeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const RestaurantBottomNav(currentIndex: 0),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _category == value;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _category = value),
      label: Text(label),
      selectedColor: AppColors.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
      ),
    );
  }

  Widget _buildDateTimePicker(
    String hint,
    DateTime? value,
    Function(DateTime) onChanged,
    bool isDark,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
          );
          if (time != null) {
            onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          }
        }
      },
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
                value != null
                    ? '${value.month}/${value.day}/${value.year} ${value.hour}:${value.minute.toString().padLeft(2, '0')}'
                    : hint,
                style: TextStyle(
                  color: value != null ? null : (isDark ? Colors.grey[500] : Colors.grey[400]),
                ),
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }
}
