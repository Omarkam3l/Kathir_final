import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/services/rush_hour_service.dart';
import '../../domain/entities/rush_hour_config.dart';

/// ViewModel for Rush Hour management
/// 
/// Handles all business logic for Rush Hour activation, deactivation,
/// and countdown timer management following MVVM pattern.
class RushHourViewModel extends ChangeNotifier {
  final RushHourService _rushHourService;

  RushHourViewModel(this._rushHourService);

  // State
  RushHourConfig? _config;
  bool _isLoading = true;
  bool _isSaving = false;
  Timer? _autoDeactivateTimer;
  Timer? _refreshTimer;

  // Form state
  bool _isActive = false;
  DateTime? _startTime;
  DateTime? _endTime;
  double _discountPercentage = 50.0;

  // Getters
  RushHourConfig? get config => _config;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isActive => _isActive;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;
  double get discountPercentage => _discountPercentage;

  // Computed properties
  bool get isRushHourActive => _isActive && _startTime != null && _endTime != null;

  int get remainingSeconds {
    if (_endTime == null || _startTime == null) return 0;
    
    final now = DateTime.now();
    final durationInSeconds = _endTime!.difference(_startTime!).inSeconds;
    final elapsedSeconds = now.difference(_startTime!.toLocal()).inSeconds;
    final remaining = durationInSeconds - elapsedSeconds;
    
    return remaining > 0 ? remaining : 0;
  }

  // Methods
  void setDiscountPercentage(double value) {
    _discountPercentage = value;
    notifyListeners();
  }

  void toggleActive() {
    _isActive = !_isActive;
    notifyListeners();
  }

  Future<void> loadRushHourConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      final config = await _rushHourService.getMyRushHour();

      _config = config;
      _isActive = config.isActive;
      _startTime = config.startTime;
      _endTime = config.endTime;
      _discountPercentage = config.discountPercentage.toDouble();
      _isLoading = false;

      if (_isActive && _endTime != null) {
        _startAutoDeactivateTimer();
        _startRefreshTimer();
      }
    } catch (e) {
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<String?> saveSettings() async {
    _isSaving = true;
    notifyListeners();

    try {
      final RushHourConfig updatedConfig;
      
      if (_isActive) {
        final nowUtc = DateTime.now().toUtc();
        final oneHourLaterUtc = nowUtc.add(const Duration(hours: 1));
        
        updatedConfig = await _rushHourService.setRushHourSettings(
          isActive: true,
          startTime: nowUtc,
          endTime: oneHourLaterUtc,
          discountPercentage: _discountPercentage.round(),
        );
        
        _startAutoDeactivateTimer();
        _startRefreshTimer();
      } else {
        updatedConfig = await _rushHourService.setRushHourSettings(
          isActive: false,
          startTime: null,
          endTime: null,
          discountPercentage: _discountPercentage.round(),
        );
        
        _cancelAutoDeactivateTimer();
        _cancelRefreshTimer();
      }

      _config = updatedConfig;
      _startTime = updatedConfig.startTime;
      _endTime = updatedConfig.endTime;
      _isSaving = false;

      notifyListeners();

      return _isActive
          ? 'Rush hour activated for 1 hour!'
          : 'Rush hour deactivated successfully!';
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return e.toString();
    }
  }

  void _startAutoDeactivateTimer() {
    _cancelAutoDeactivateTimer();
    
    if (_endTime == null) return;
    
    final now = DateTime.now();
    final localEndTime = _endTime!.toLocal();
    final timeUntilEnd = localEndTime.difference(now);
    
    if (timeUntilEnd.isNegative) {
      _autoDeactivate();
      return;
    }
    
    _autoDeactivateTimer = Timer(timeUntilEnd, () {
      _autoDeactivate();
    });
  }

  void _startRefreshTimer() {
    _cancelRefreshTimer();
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_endTime != null) {
        final now = DateTime.now();
        final localEndTime = _endTime!.toLocal();
        if (now.isAfter(localEndTime)) {
          _autoDeactivate();
        } else {
          notifyListeners();
        }
      }
    });
  }

  void _cancelAutoDeactivateTimer() {
    _autoDeactivateTimer?.cancel();
    _autoDeactivateTimer = null;
  }

  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _autoDeactivate() async {
    _cancelAutoDeactivateTimer();
    _cancelRefreshTimer();
    
    _isActive = false;
    
    try {
      final updatedConfig = await _rushHourService.setRushHourSettings(
        isActive: false,
        startTime: null,
        endTime: null,
        discountPercentage: _discountPercentage.round(),
      );
      
      _config = updatedConfig;
      _startTime = null;
      _endTime = null;
      
      notifyListeners();
    } catch (e) {
      // Silent fail
    }
  }

  @override
  void dispose() {
    _cancelAutoDeactivateTimer();
    _cancelRefreshTimer();
    super.dispose();
  }
}
