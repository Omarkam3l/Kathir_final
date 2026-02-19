import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/services/rush_hour_service.dart';
import '../../domain/entities/rush_hour_config.dart';

class RestaurantSurplusSettingsScreen extends StatefulWidget {
  const RestaurantSurplusSettingsScreen({super.key});

  @override
  State<RestaurantSurplusSettingsScreen> createState() =>
      _RestaurantSurplusSettingsScreenState();
}

class _RestaurantSurplusSettingsScreenState
    extends State<RestaurantSurplusSettingsScreen> {
  late final RushHourService _rushHourService;

  RushHourConfig? _config;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form state
  bool _isActive = false;
  DateTime? _startTime;
  DateTime? _endTime;
  double _discountPercentage = 50.0;

  @override
  void initState() {
    super.initState();
    _rushHourService = RushHourService(Supabase.instance.client);
    _loadRushHourConfig();
  }

  Future<void> _loadRushHourConfig() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final config = await _rushHourService.getMyRushHour();

      if (!mounted) return;

      setState(() {
        _config = config;
        _isActive = config.isActive;
        _startTime = config.startTime ?? _getDefaultStartTime();
        _endTime = config.endTime ?? _getDefaultEndTime();
        _discountPercentage = config.discountPercentage.toDouble();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        // Set defaults on error
        _startTime = _getDefaultStartTime();
        _endTime = _getDefaultEndTime();
      });
    }
  }

  DateTime _getDefaultStartTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 21, 0); // 9 PM today
  }

  DateTime _getDefaultEndTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 0); // 11 PM today
  }

  Future<void> _saveSettings() async {
    if (!mounted) return;

    // Validation
    if (_isActive) {
      if (_startTime == null || _endTime == null) {
        _showError('Please select start and end times');
        return;
      }

      if (_endTime!.isBefore(_startTime!) ||
          _endTime!.isAtSameMomentAs(_startTime!)) {
        _showError('End time must be after start time');
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedConfig = await _rushHourService.setRushHourSettings(
        isActive: _isActive,
        startTime: _startTime,
        endTime: _endTime,
        discountPercentage: _discountPercentage.round(),
      );

      if (!mounted) return;

      setState(() {
        _config = updatedConfig;
        _isSaving = false;
      });

      _showSuccess(
        _isActive
            ? 'Rush hour activated successfully!'
            : 'Rush hour deactivated successfully!',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime ?? now),
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _startTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _selectEndTime() async {
    final now = DateTime.now();
    final initialDate = _endTime ?? _startTime ?? now;
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startTime ?? now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime ?? now),
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _endTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF221910) : const Color(0xFFF8F7F6),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Surplus Settings'),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF2D241B) : Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRushHourCard(isDark),
                  const SizedBox(height: 16),
                  _buildDiscountCard(isDark),
                  const SizedBox(height: 24),
                  _buildSaveButton(isDark),
                  if (_config?.activeNow == true) ...[
                    const SizedBox(height: 16),
                    _buildActiveNowBanner(isDark),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildRushHourCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D241B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rush Hour',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1B140D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'High discount period',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isActive
                      ? AppColors.primaryGreen.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isActive ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isActive
                            ? AppColors.primaryGreen
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeThumbColor: AppColors.primaryGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelector(
                  label: 'Start Time',
                  time: _startTime,
                  onTap: _selectStartTime,
                  isDark: isDark,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                child: Text(
                  '—',
                  style: TextStyle(
                    fontSize: 20,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: _buildTimeSelector(
                  label: 'End Time',
                  time: _endTime,
                  onTap: _selectEndTime,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required DateTime? time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF221910).withValues(alpha: 0.5)
                  : const Color(0xFFF8F7F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF4A3F33)
                    : const Color(0xFFE7E5E4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time != null ? timeFormat.format(time) : '--:--',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1B140D),
                        ),
                      ),
                      if (time != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(time),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.access_time,
                  color: isDark ? Colors.white54 : Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D241B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Discount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1B140D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applied during rush hours',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
              Text(
                '${_discountPercentage.round()}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primaryGreen,
              inactiveTrackColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
              thumbColor: AppColors.primaryGreen,
              overlayColor: AppColors.primaryGreen.withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
            ),
            child: Slider(
              value: _discountPercentage,
              min: 10,
              max: 80,
              divisions: 14,
              onChanged: (value) {
                setState(() {
                  _discountPercentage = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '10%',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
                Text(
                  '80%',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveSettings,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Save Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildActiveNowBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rush Hour Active Now!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'All meals are showing rush hour discount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
