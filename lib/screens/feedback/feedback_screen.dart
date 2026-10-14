import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../models/feedback_question.dart';
import '../../providers/feedback_provider.dart';

class FeedbackScreen extends StatefulWidget {
  final FeedbackProvider? provider;

  const FeedbackScreen({super.key, this.provider});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  late final FeedbackProvider _provider;
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  late final ScrollController _scrollController;
  final Map<int, TextEditingController> _controllers = {};
  String? _nameError;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? FeedbackProvider();
    _nameController = TextEditingController(
      text: StorageService.getUserName() ?? '',
    );
    _nameFocusNode = FocusNode();
    _scrollController = ScrollController();
    _nameController.addListener(() {
      setState(() {
        if (_nameController.text.trim().isNotEmpty) {
          _nameError = null;
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider.loadQuestions();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _scrollController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(FeedbackQuestion q) {
    if (!_controllers.containsKey(q.id)) {
      _controllers[q.id] = TextEditingController(
        text: q.answerText ?? _provider.answers[q.id] ?? '',
      );
      _controllers[q.id]!.addListener(() {
        _provider.setAnswer(q.id, _controllers[q.id]!.text);
      });
    }
    return _controllers[q.id]!;
  }

  Future<void> _handleSubmit() async {
    // 1. Ensure all active controllers sync back to provider
    for (final entry in _controllers.entries) {
      _provider.setAnswer(entry.key, entry.value.text);
    }

    // 2. Validate form and mandatory name field
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final name = _nameController.text.trim();
    if (!isFormValid || name.isEmpty) {
      setState(() {
        _autoValidateMode = AutovalidateMode.always;
        _nameError = 'Please enter your name';
      });
      _nameFocusNode.requestFocus();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please enter your name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.favoriteRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 3. Ensure at least one question is answered
    final hasAnswers = _controllers.values.any((c) => c.text.trim().isNotEmpty);
    if (!hasAnswers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please answer at least one question',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.favoriteRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final success = await _provider.submitFeedback(
      name: name,
    );

    if (!mounted) return;

    if (success) {
      await StorageService.saveUserName(name);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E6B4F),
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'நன்றி! (Thank You!)',
                style: GoogleFonts.hindMadurai(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'உங்கள் கருத்துக்கள் மற்றும் ஆலோசனைகள் வெற்றிகரமாக பதிவு செய்யப்பட்டன.\nYour feedback has been received and helps us serve better.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hindMadurai(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.sunriseGold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'முடிந்தது (Done)',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _provider.errorMessage!,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: AppColors.favoriteRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final questions = _provider.questions;
        final isLoading = _provider.isLoading;
        final isSubmitting = _provider.isSubmitting;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'கருத்துக்கள் (Feedback)',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Convention & Worship Feedback',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.amberGlow.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.sunriseGold,
            onRefresh: () => _provider.loadQuestions(forceRefresh: true),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Intro Banner
                    _buildIntroCard(),

                    const SizedBox(height: 20),

                    if (isLoading && questions.isEmpty)
                      _buildLoadingSkeleton()
                    else if (questions.isEmpty)
                      _buildEmptyState()
                    else ...[
                      // Name Field at the top of questions
                      _buildNameCard(),

                      // Render Questions
                      ...questions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final question = entry.value;
                        return _buildQuestionCard(question, index + 1);
                      }),

                      const SizedBox(height: 20),

                      // Real-time helper if name is empty
                      if (_nameController.text.trim().isEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.favoriteRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.favoriteRed.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: AppColors.favoriteRed,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Name is required to submit',
                                  style: GoogleFonts.hindMadurai(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.favoriteRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: AppColors.sunriseGold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: isSubmitting
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.send_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'கருத்துக்களை சமர்ப்பிக்கவும் (Submit Feedback)',
                                        style: GoogleFonts.hindMadurai(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.sunriseGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'உங்கள் ஆலோசனைகள் முக்கியம்',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'கிருபையாய் உங்கள் கருத்துக்களையும் ஆலோசனைகளையும் பகிர்ந்து, தேவனுடைய ஊழியம் மேலும் சிறப்பாக வளர உதவுங்கள்.',
                  style: GoogleFonts.hindMadurai(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(FeedbackQuestion question, int number) {
    final controller = _getController(question);
    final isAnswered = question.answered;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Number & Answered badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'கேள்வி (Q) $number',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isAnswered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E6B4F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF2E6B4F)),
                      const SizedBox(width: 4),
                      Text(
                        'பதிலளிக்கப்பட்டது',
                        style: GoogleFonts.hindMadurai(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E6B4F),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Question Text
          Text(
            question.questionText,
            style: GoogleFonts.hindMadurai(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),

          if (question.description != null && question.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              question.description!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Answer Input Field
          TextField(
            controller: controller,
            maxLines: 3,
            style: GoogleFonts.hindMadurai(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'உங்கள் பதிலை இங்கே எழுதுங்கள்...\nWrite your response here...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.scaffoldBackground,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.sunriseGold, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'கேள்விகள் எதுவும் கிடைக்கவில்லை',
            style: GoogleFonts.hindMadurai(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No feedback questions available at the moment.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 140,
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
    );
  }

  Widget _buildNameCard() {
    final hasError = _nameError != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasError ? AppColors.favoriteRed : AppColors.cardBorder,
          width: hasError ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasError
                ? AppColors.favoriteRed.withValues(alpha: 0.08)
                : AppColors.primaryDark.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasError
                      ? AppColors.favoriteRed.withValues(alpha: 0.12)
                      : AppColors.primaryLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: hasError ? AppColors.favoriteRed : AppColors.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'உங்கள் பெயர் (Your Name) *',
                      style: GoogleFonts.hindMadurai(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Name (Required)',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.favoriteRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            autovalidateMode: _autoValidateMode,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.poppins(fontSize: 14),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              filled: true,
              fillColor: AppColors.scaffoldBackground,
              errorText: _nameError,
              errorStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.favoriteRed,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError ? AppColors.favoriteRed : AppColors.cardBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError ? AppColors.favoriteRed : AppColors.sunriseGold,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.favoriteRed, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.favoriteRed, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
