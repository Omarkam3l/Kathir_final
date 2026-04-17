/// Phone number formatter utility for Egyptian phone numbers
/// Converts 01xxxxxxxxx to 201xxxxxxxxx format for WhatsApp compatibility
class PhoneFormatter {
  /// Formats Egyptian phone number to international format (201xxxxxxxxx)
  /// 
  /// Examples:
  /// - "01012345678" -> "201012345678"
  /// - "1012345678" -> "201012345678"
  /// - "201012345678" -> "201012345678" (already formatted)
  /// - "+201012345678" -> "201012345678" (removes +)
  /// - "0100 123 4567" -> "201001234567" (removes spaces)
  static String formatEgyptianPhone(String phone) {
    if (phone.isEmpty) return phone;
    
    // Remove all non-digit characters (spaces, dashes, parentheses, +)
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If already starts with 20, return as is
    if (cleaned.startsWith('20')) {
      return cleaned;
    }
    
    // If starts with 0, remove it and add 20
    if (cleaned.startsWith('0')) {
      return '20${cleaned.substring(1)}';
    }
    
    // If starts with 1 (missing leading 0), add 20
    if (cleaned.startsWith('1')) {
      return '20$cleaned';
    }
    
    // Otherwise, assume it needs 20 prefix
    return '20$cleaned';
  }
  
  /// Validates Egyptian phone number format
  /// Returns true if phone is valid Egyptian mobile number
  static bool isValidEgyptianPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Remove country code if present
    if (cleaned.startsWith('20')) {
      cleaned = cleaned.substring(2);
    }
    
    // Remove leading 0 if present
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    
    // Egyptian mobile numbers start with 1 and are 10 digits total (including the 1)
    // Valid prefixes: 10, 11, 12, 15
    return cleaned.length == 10 && 
           cleaned.startsWith('1') &&
           RegExp(r'^1[0125]\d{8}$').hasMatch(cleaned);
  }
  
  /// Formats phone for display (adds spaces for readability)
  /// Example: "201012345678" -> "+20 10 1234 5678"
  static String formatForDisplay(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.startsWith('20') && cleaned.length == 12) {
      return '+20 ${cleaned.substring(2, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8)}';
    }
    
    return phone;
  }
}
