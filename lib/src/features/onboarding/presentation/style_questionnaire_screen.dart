import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import 'package:clothwise/src/features/onboarding/data/style_questions.dart';
import 'package:clothwise/src/app/router.dart';
import 'package:clothwise/src/core/services/preferences_service.dart';

/// Style questionnaire screen - Collects user style preferences
class StyleQuestionnaireScreen extends ConsumerStatefulWidget {
  const StyleQuestionnaireScreen({super.key});

  @override
  ConsumerState<StyleQuestionnaireScreen> createState() =>
      _StyleQuestionnaireScreenState();
}

class _StyleQuestionnaireScreenState
    extends ConsumerState<StyleQuestionnaireScreen> {
  final PageController _pageController = PageController();
  final Map<int, String> _answers = {};
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveAnswersAndContinue() async {
    // Save answers to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('style_questionnaire_completed', true);

    // Save each answer
    _answers.forEach((questionId, answer) async {
      await prefs.setString('style_answer_$questionId', answer);
    });

    // Mark onboarding as complete
    await PreferencesService.setOnboardingComplete();

    if (mounted) {
      // Navigate to login screen
      context.go(RoutePaths.login);
    }
  }

  Future<void> _skipQuestionnaire() async {
    // Mark onboarding as complete even if skipped
    await PreferencesService.setOnboardingComplete();

    if (mounted) {
      context.go(RoutePaths.login);
    }
  }

  void _selectAnswer(int questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
    });

    // Auto-advance to next question after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      // Check if widget is still mounted before performing navigation
      if (!mounted) return;

      if (_currentPage < styleQuestions.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Last question answered, save and continue
        _saveAnswersAndContinue();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Style Preferences', style: theme.textTheme.headlineLarge),
        actions: [
          TextButton(
            onPressed: _skipQuestionnaire,
            child: Text(
              'Skip',
              style: AppTextStyles.bodyRegular.copyWith(
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Question ${_currentPage + 1} of ${styleQuestions.length}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / styleQuestions.length,
                    backgroundColor: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // Questions PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable manual swiping
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: styleQuestions.length,
              itemBuilder: (context, index) {
                final question = styleQuestions[index];
                return _QuestionPage(
                  question: question,
                  selectedAnswer: _answers[question.id],
                  onAnswerSelected: (answer) => _selectAnswer(question.id, answer),
                );
              },
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _answers.containsKey(styleQuestions[_currentPage].id)
                        ? () {
                            if (_currentPage < styleQuestions.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _saveAnswersAndContinue();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: Text(
                      _currentPage < styleQuestions.length - 1 ? 'Next' : 'Finish',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
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

/// Individual question page widget
class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  final StyleQuestion question;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            question.question,
            style: AppTextStyles.h2.copyWith(
              color: theme.textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Answer choices
          ...question.choices.map((choice) {
            final isSelected = selectedAnswer == choice;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: InkWell(
                onTap: () => onAnswerSelected(choice),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          choice,
                          style: AppTextStyles.bodyRegular.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyLarge?.color,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
