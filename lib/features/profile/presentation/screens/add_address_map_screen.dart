import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/services/geocoding_service.dart';

/// Map-based address selector for users
/// Allows users to select address location from an interactive map
class AddAddressMapScreen extends StatefulWidget {
  final String? initialLabel;
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const AddAddressMapScreen({
    super.key,
    this.initialLabel,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<AddAddressMapScreen> createState() => _AddAddressMapScreenState();
}

class _AddAddressMapScreenState extends State<AddAddressMapScreen> {
  final MapController _mapController = MapController();
  final GeocodingService _geocodingService = GeocodingService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  bool _isLoadingLocation = false;
  
  late LatLng _selectedLocation;
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    
    // Initialize with provided values or defaults
    _selectedLocation = LatLng(
      widget.initialLatitude ?? 30.0444, // Default: Cairo
      widget.initialLongitude ?? 31.2357,
    );
    _selectedAddress = widget.initialAddress ?? '';
    _searchController.text = _selectedAddress;
    _labelController.text = widget.initialLabel ?? '';
    
    // Get current location if no initial location provided
    if (widget.initialLatitude == null || widget.initialLongitude == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _labelController.dispose();
    _searchFocusNode.dispose();
    _geocodingService.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      
      final address = await _geocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _selectedAddress = address ?? 'Current Location';
          _searchController.text = _selectedAddress;
          _isLoadingLocation = false;
        });
        
        _mapController.move(_selectedLocation, 14.0);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _geocodingService.debouncedSearch(
        query,
        const Duration(milliseconds: 500),
      );

      setState(() {
        _searchResults = results;
        _showSearchResults = results.isNotEmpty;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  void _selectSearchResult(GeocodingResult result) {
    setState(() {
      _selectedLocation = LatLng(result.latitude, result.longitude);
      _selectedAddress = result.displayName;
      _searchController.text = result.displayName;
      _showSearchResults = false;
    });

    _searchFocusNode.unfocus();
    _mapController.move(_selectedLocation, 14.0);
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoadingLocation = true;
    });

    try {
      final address = await _geocodingService.reverseGeocode(
        location.latitude,
        location.longitude,
      );

      if (mounted) {
        setState(() {
          _selectedAddress = address ?? 'Selected Location';
          _searchController.text = _selectedAddress;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      if (mounted) {
        setState(() {
          _selectedAddress = 'Selected Location';
          _searchController.text = _selectedAddress;
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _confirmLocation() {
    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a label for this address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.pop({
      'label': _labelController.text.trim(),
      'address': _selectedAddress,
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(isDark),
            _buildTopBar(isDark),
            if (_showSearchResults) _buildSearchResults(isDark),
            _buildBottomSheet(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selectedLocation,
        initialZoom: 13.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        onTap: _onMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _selectedLocation,
              width: 50,
              height: 50,
              child: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 50,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2E22) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black,
                    size: 24,
                  ),
                  padding: const EdgeInsets.all(16),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _searchLocation,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _showSearchResults = false;
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      size: 24,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    padding: const EdgeInsets.all(16),
                  )
                else
                  IconButton(
                    onPressed: _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.my_location,
                            color: AppColors.primary,
                            size: 24,
                          ),
                    padding: const EdgeInsets.all(16),
                    tooltip: 'My Location',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return Positioned(
      top: 88,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          itemCount: _searchResults.length,
          separatorBuilder: (_, __) => Divider(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                result.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _selectSearchResult(result),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomSheet(bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialLabel == null ? 'Add Address' : 'Edit Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Label (e.g., Home, Work)',
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: const Icon(Icons.label, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F1F16) : Colors.grey[50],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAddress.isEmpty
                          ? 'Tap on map to select location'
                          : _selectedAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.initialLabel == null ? 'Add Address' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
