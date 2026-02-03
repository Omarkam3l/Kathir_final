import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/auth_logger.dart';
import '../blocs/auth_provider.dart';

/// Screen shown to restaurant/NGO users whose accounts are pending approval.
/// Handles legal document upload AFTER OTP verification when user is authenticated.
class PendingApprovalScreen extends StatefulWidget {
  static const routeName = '/pending-approval';
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

enum UploadState { idle, uploading, success, error }

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  UploadState _uploadState = UploadState.idle;
  String? _uploadError;
  String? _uploadedFileName;
  bool _isLoading = true;
  List<String>? _existingDocs;

  @override
  void initState() {
    super.initState();
    _checkExistingDocuments();
  }

  Future<void> _checkExistingDocuments() async {
    try {
      final client = s.Supabase.instance.client;
      final user = client.auth.currentUser;
      final authProvider = context.read<AuthProvider>();
      final role = authProvider.user?.role;

      if (user == null || role == null) {
        setState(() => _isLoading = false);
        return;
      }

      AuthLogger.info('📋 CHECK_DOCS: Starting', ctx: {
        'userId': user.id,
        'role': role,
      });

      // Check if documents already uploaded
      if (role == 'restaurant') {
        final result = await client
            .from('restaurants')
            .select('legal_docs_urls')
            .eq('profile_id', user.id)
            .single();

        final urls = result['legal_docs_urls'] as List?;
        _existingDocs = urls?.cast<String>();
      } else if (role == 'ngo') {
        final result = await client
            .from('ngos')
            .select('legal_docs_urls')
            .eq('profile_id', user.id)
            .single();

        final urls = result['legal_docs_urls'] as List?;
        _existingDocs = urls?.cast<String>();
      }

      AuthLogger.info('✅ CHECK_DOCS: Complete', ctx: {
        'hasDocuments': _existingDocs != null && _existingDocs!.isNotEmpty,
        'docCount': _existingDocs?.length ?? 0,
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_existingDocs != null && _existingDocs!.isNotEmpty) {
            _uploadState = UploadState.success;
          }
        });
      }
    } catch (e, stackTrace) {
      AuthLogger.errorLog('❌ CHECK_DOCS: Failed', ctx: {}, error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadDocument() async {
    AuthLogger.info('📤 UPLOAD: Opening file picker', ctx: {});

    final res = await FilePicker.platform.pickFiles(
      withReadStream: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'doc', 'docx'],
    );

    if (!mounted) return;

    if (res == null || res.files.isEmpty) {
      AuthLogger.info('❌ UPLOAD: Cancelled', ctx: {});
      return;
    }

    final file = res.files.first;
    final fileName = file.name;
    final fileSize = file.size;
    final fileBytes = file.bytes;

    if (fileBytes == null) {
      _showError('Could not read file');
      return;
    }

    // Validate file size (max 10MB)
    if (fileSize > 10 * 1024 * 1024) {
      AuthLogger.warn('⚠️ UPLOAD: File too large', ctx: {
        'fileSize': fileSize,
        'maxSize': 10 * 1024 * 1024,
      });
      _showError('File too large! Maximum size is 10MB');
      return;
    }

    setState(() {
      _uploadState = UploadState.uploading;
      _uploadedFileName = fileName;
    });

    try {
      final client = s.Supabase.instance.client;
      final user = client.auth.currentUser;
      final authProvider = context.read<AuthProvider>();
      final role = authProvider.user?.role;

      if (user == null || role == null) {
        throw Exception('User not authenticated');
      }

      // ============================================
      // STEP 1: Prepare Upload
      // ============================================
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploadPath = '${user.id}/${timestamp}_$fileName';

      AuthLogger.info('📤 UPLOAD_STEP_1: Initialization', ctx: {
        'bucket': 'legal_docs_bucket',
        'path': uploadPath,
        'fileName': fileName,
        'fileSize': fileSize,
        'userId': user.id,
        'role': role,
      });

      // ============================================
      // STEP 2: Determine MIME Type
      // ============================================
      String contentType;
      final lowerFileName = fileName.toLowerCase();

      if (lowerFileName.endsWith('.pdf')) {
        contentType = 'application/pdf';
      } else if (lowerFileName.endsWith('.jpg') || lowerFileName.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (lowerFileName.endsWith('.png')) {
        contentType = 'image/png';
      } else if (lowerFileName.endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (lowerFileName.endsWith('.doc')) {
        contentType = 'application/msword';
      } else if (lowerFileName.endsWith('.docx')) {
        contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else {
        contentType = 'application/octet-stream';
      }

      AuthLogger.info('📄 UPLOAD_STEP_2: MIME Type', ctx: {
        'contentType': contentType,
      });

      // ============================================
      // STEP 3: Upload to Storage
      // ============================================
      final uploadData = Uint8List.fromList(fileBytes);

      AuthLogger.info('🚀 UPLOAD_STEP_3: Starting Upload', ctx: {
        'dataSize': uploadData.length,
      });

      await client.storage.from('legal_docs_bucket').uploadBinary(
            uploadPath,
            uploadData,
            fileOptions: s.FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      AuthLogger.info('✅ UPLOAD_STEP_3: Upload Complete', ctx: {});

      // ============================================
      // STEP 4: Get Public URL
      // ============================================
      final publicUrl = client.storage.from('legal_docs_bucket').getPublicUrl(uploadPath);

      AuthLogger.info('🔗 UPLOAD_STEP_4: Public URL Generated', ctx: {
        'publicUrl': publicUrl,
      });

      // ============================================
      // STEP 5: Save URL to Database
      // ============================================
      AuthLogger.info('💾 UPLOAD_STEP_5: Saving to Database', ctx: {
        'role': role,
      });

      if (role == 'restaurant') {
        await client.rpc('append_restaurant_legal_doc', params: {'p_url': publicUrl});
      } else if (role == 'ngo') {
        await client.rpc('append_ngo_legal_doc', params: {'p_url': publicUrl});
      }

      AuthLogger.info('✅ UPLOAD_STEP_5: Saved to Database', ctx: {});

      // ============================================
      // STEP 6: Verify Save
      // ============================================
      await _checkExistingDocuments();

      AuthLogger.info('🎉 UPLOAD_COMPLETE: Success', ctx: {
        'fileName': fileName,
        'publicUrl': publicUrl,
      });

      if (mounted) {
        setState(() {
          _uploadState = UploadState.success;
        });
        _showSuccess('Document uploaded successfully!');
      }
    } catch (e, stackTrace) {
      final errorString = e.toString();

      // Analyze error
      String errorCategory = 'UNKNOWN';
      if (errorString.contains('row-level security') || errorString.contains('RLS')) {
        errorCategory = 'RLS_POLICY_ERROR';
      } else if (errorString.contains('mime type')) {
        errorCategory = 'MIME_TYPE_ERROR';
      } else if (errorString.contains('not found')) {
        errorCategory = 'BUCKET_NOT_FOUND';
      }

      AuthLogger.errorLog('❌ UPLOAD_FAILED', ctx: {
        'errorCategory': errorCategory,
        'fileName': fileName,
      }, error: e, stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _uploadState = UploadState.error;
          _uploadError = errorString;
        });
        _showError('Upload failed: ${errorString.length > 50 ? '${errorString.substring(0, 50)}...' : errorString}');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final isRestaurant = user?.role == 'restaurant';
    final hasDocuments = _existingDocs != null && _existingDocs!.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: hasDocuments
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasDocuments ? Icons.hourglass_top_rounded : Icons.upload_file,
                        size: 64,
                        color: hasDocuments ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      hasDocuments ? 'Account Pending Approval' : 'Upload Legal Documents',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Message
                    Text(
                      hasDocuments
                          ? (isRestaurant
                              ? 'Your restaurant account is being reviewed by our team. '
                                  'This usually takes 1-2 business days.'
                              : 'Your organization account is being reviewed by our team. '
                                  'This usually takes 1-2 business days.')
                          : 'Please upload your legal documents (Business License, Registration Certificate, etc.) to complete your registration.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Upload Section or Status Section
                    if (!hasDocuments) ...[
                      _buildUploadSection(isDark),
                    ] else ...[
                      _buildStatusSection(isDark, isRestaurant),
                    ],

                    const Spacer(),

                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthProvider>().signOut();
                          context.go('/auth');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUploadSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _uploadState == UploadState.error
              ? AppColors.error
              : _uploadState == UploadState.success
                  ? Colors.green
                  : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          width: _uploadState != UploadState.idle ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _uploadState == UploadState.success
                ? Icons.check_circle
                : _uploadState == UploadState.error
                    ? Icons.error_outline
                    : Icons.cloud_upload_outlined,
            size: 48,
            color: _uploadState == UploadState.success
                ? Colors.green
                : _uploadState == UploadState.error
                    ? AppColors.error
                    : AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            _uploadState == UploadState.uploading
                ? 'Uploading...'
                : _uploadState == UploadState.success
                    ? 'Document Uploaded!'
                    : _uploadState == UploadState.error
                        ? 'Upload Failed'
                        : 'Upload Document',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supported formats: PDF, JPG, PNG, GIF, DOC, DOCX\nMaximum size: 10MB',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_uploadedFileName != null && _uploadState == UploadState.success) ...[
            const SizedBox(height: 12),
            Text(
              _uploadedFileName!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_uploadError != null && _uploadState == UploadState.error) ...[
            const SizedBox(height: 12),
            Text(
              _uploadError!.length > 100 ? '${_uploadError!.substring(0, 100)}...' : _uploadError!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          if (_uploadState != UploadState.uploading)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadDocument,
                icon: Icon(_uploadState == UploadState.error ? Icons.refresh : Icons.upload_file),
                label: Text(_uploadState == UploadState.error ? 'Retry Upload' : 'Choose File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusSection(bool isDark, bool isRestaurant) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          _buildStep(context, '1', 'Our team reviews your details', isDark),
          const SizedBox(height: 8),
          _buildStep(context, '2', 'You receive an email notification', isDark),
          const SizedBox(height: 8),
          _buildStep(context, '3', 'Start using all features!', isDark),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
