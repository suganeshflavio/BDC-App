import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../models/prayer_request.dart';
import '../../providers/prayer_request_provider.dart';

class PrayerRequestsScreen extends StatefulWidget {
  final PrayerRequestProvider? provider;

  const PrayerRequestsScreen({super.key, this.provider});

  @override
  State<PrayerRequestsScreen> createState() => _PrayerRequestsScreenState();
}

class _PrayerRequestsScreenState extends State<PrayerRequestsScreen> {
  late final PrayerRequestProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? PrayerRequestProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider.loadPrayerRequests();
      }
    });
  }

  Future<void> _callHelpline() async {
    final uri = Uri.parse('tel:9443694891');
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Could not launch helpline: $e');
    }
  }

  void _showNewRequestDialog() {
    final nameController = TextEditingController(
      text: StorageService.getUserName() ?? '',
    );
    final mobileController = TextEditingController(
      text: StorageService.getUserPhone() ?? '',
    );
    final descController = TextEditingController();
    final voiceNoteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSubmittingLocal = false;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title & Subtitle
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.sunriseGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'புதிய ஜெப விண்ணப்பம்',
                                  style: GoogleFonts.hindMadurai(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Text(
                                  'New Prayer Request • Bethesda Prayer Tower',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      Text(
                        'பெயர் (Name) *',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'உங்கள் பெயர் / Your Name',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                          filled: true,
                          fillColor: AppColors.scaffoldBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your name (பெயர் தேவை)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Mobile Field
                      Text(
                        'தொலைபேசி எண் (Mobile Number) *',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '10 இலக்க எண் (Mobile No)',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          filled: true,
                          fillColor: AppColors.scaffoldBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter mobile number (தொலைபேசி எண் தேவை)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Description Field
                      Text(
                        'ஜெப தேவை (Prayer Description) *',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descController,
                        maxLines: 4,
                        style: GoogleFonts.hindMadurai(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'உங்கள் ஜெப தேவையை விரிவாக எழுதுங்கள்...\nShare your prayer request in detail...',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: AppColors.scaffoldBackground,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please describe your prayer need (ஜெப தேவை தேவை)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Voice Note URL (Optional)
                      Text(
                        'குரல் பதிவு முகவரி (Voice Note URL - Optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: voiceNoteController,
                        keyboardType: TextInputType.url,
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'https://example.com/audio.m4a (Optional)',
                          prefixIcon: const Icon(Icons.mic_none_rounded, size: 20),
                          filled: true,
                          fillColor: AppColors.scaffoldBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmittingLocal
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSubmittingLocal = true);

                                  final success = await _provider.createPrayerRequest(
                                    name: nameController.text.trim(),
                                    mobile: mobileController.text.trim(),
                                    description: descController.text.trim(),
                                    voiceNoteUrl: voiceNoteController.text.trim().isNotEmpty
                                        ? voiceNoteController.text.trim()
                                        : null,
                                  );

                                  if (modalContext.mounted) {
                                    setModalState(() => isSubmittingLocal = false);
                                  }
                                  if (ctx.mounted && success) {
                                    Navigator.of(ctx).pop();
                                  }
                                  if (!mounted) return;
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.white),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'ஜெப விண்ணப்பம் வெற்றிகரமாக அனுப்பப்பட்டது!\nPrayer request received. Our prayer team is praying for you.',
                                                style: GoogleFonts.hindMadurai(fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF2E6B4F),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _provider.errorMessage ?? 'Could not submit prayer request.',
                                          style: GoogleFonts.poppins(fontSize: 13),
                                        ),
                                        backgroundColor: AppColors.favoriteRed,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: AppColors.sunriseGold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: isSubmittingLocal
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.sunriseGold,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.send_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'விண்ணப்பிக்கவும் (Submit Request)',
                                      style: GoogleFonts.hindMadurai(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(PrayerRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.favoriteRed, size: 24),
            const SizedBox(width: 8),
            Text(
              'விண்ணப்பத்தை நீக்கவா?',
              style: GoogleFonts.hindMadurai(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        content: Text(
          'இந்த ஜெப விண்ணப்பத்தை நீக்க விரும்புகிறீர்களா?\nAre you sure you want to delete this pending prayer request?',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'ரத்து செய் (Cancel)',
              style: GoogleFonts.poppins(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.favoriteRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _provider.deletePrayerRequest(request.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prayer request deleted successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _provider.errorMessage ?? 'Failed to delete prayer request. Only pending requests can be deleted.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.favoriteRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final requests = _provider.requests;
        final isLoading = _provider.isLoading;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ஜெப விண்ணப்பம்',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Prayer Requests • Bethesda Deliverance Church',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.amberGlow.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.sunriseGold),
                tooltip: '24/7 Prayer Helpline',
                onPressed: _callHelpline,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: () => _provider.loadPrayerRequests(refresh: true),
              ),
              const SizedBox(width: 4),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showNewRequestDialog,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.sunriseGold,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              'விண்ணப்பம் சேர்க்க',
              style: GoogleFonts.hindMadurai(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.sunriseGold,
            onRefresh: () => _provider.loadPrayerRequests(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // 1. 24/7 Helpline Banner
                  _buildHelplineCard(),

                  const SizedBox(height: 16),

                  // 2. Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'உங்கள் விண்ணப்பங்கள்',
                              style: GoogleFonts.hindMadurai(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (requests.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${requests.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _showNewRequestDialog,
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: Text(
                            '+ New',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Requests List or Loading or Empty
                  if (isLoading && requests.isEmpty)
                    _buildLoadingSkeleton()
                  else if (requests.isEmpty)
                    _buildEmptyState()
                  else
                    ...requests.map((req) => _buildPrayerCard(req)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelplineCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B38), Color(0xFF384370)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B38).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              color: AppColors.sunriseGold,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24/7 ஜெப உதவி மையம்',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bethesda 24/7 Prayer Helpline: 94436-94891',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.amberGlow,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _callHelpline,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sunriseGold,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            child: Text(
              'Call',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(PrayerRequest request) {
    final isPending = request.isPending;
    final dateStr = request.createdAt != null
        ? '${request.createdAt!.day}/${request.createdAt!.month}/${request.createdAt!.year}'
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppColors.sunriseGold.withValues(alpha: 0.15)
                        : const Color(0xFF2E6B4F).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPending
                          ? AppColors.sunriseGold.withValues(alpha: 0.5)
                          : const Color(0xFF2E6B4F).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPending ? Icons.schedule_rounded : Icons.check_circle_rounded,
                        size: 14,
                        color: isPending ? AppColors.sunriseAmber : const Color(0xFF2E6B4F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPending ? 'Pending (பரிசீலனையில்)' : 'Prayed (ஜெபிக்கப்பட்டது)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPending ? AppColors.primaryDark : const Color(0xFF2E6B4F),
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (isPending) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: AppColors.favoriteRed,
                        tooltip: 'Delete Request',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmDelete(request),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              request.description,
              style: GoogleFonts.hindMadurai(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 8),

            // Seeker details
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  request.name.isNotEmpty ? request.name : 'Member',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (request.mobile.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    request.mobile,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const Spacer(),
                if (request.voiceNoteUrl != null && request.voiceNoteUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(request.voiceNoteUrl!);
                      if (uri != null) {
                        try {
                          await launchUrl(uri);
                        } catch (_) {}
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.audiotrack_rounded, size: 12, color: AppColors.primaryDark),
                          const SizedBox(width: 4),
                          Text(
                            'Voice Note',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.sunriseGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.primaryDark,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ஜெப விண்ணப்பங்கள் எதுவும் இல்லை',
            textAlign: TextAlign.center,
            style: GoogleFonts.hindMadurai(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"கேளுங்கள், அப்பொழுது உங்களுக்குக் கொடுக்கப்படும்; தேடுங்கள், அப்பொழுது கண்டடைவீர்கள்" - மத்தேயு 7:7\n\nSubmit your prayer requests. Our church pastors and prayer warriors will intercede for you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hindMadurai(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showNewRequestDialog,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'விண்ணப்பிக்கவும் (Submit Request)',
              style: GoogleFonts.hindMadurai(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.sunriseGold,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.sunriseGold,
              ),
            ),
          );
        }),
      ),
    );
  }
}
