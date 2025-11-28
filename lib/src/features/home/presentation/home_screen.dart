import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clothwise/src/app/router.dart';
import 'package:clothwise/src/app/theme/app_colors.dart';
import 'package:clothwise/src/app/theme/app_spacing.dart';
import 'package:clothwise/src/app/theme/app_text_styles.dart';
import 'package:clothwise/src/features/recommendations/presentation/recommendations_screen.dart';
import 'package:clothwise/src/features/home/data/datasources/outfit_storage_service.dart';
import 'package:clothwise/src/features/home/presentation/outfit_detail_screen.dart';

/// Home screen - Upload photo for outfit recommendations
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Navigate to recommendations screen
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecommendationsScreen(
              imagePath: image.path,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        // Navigate to recommendations screen
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecommendationsScreen(
              imagePath: photo.path,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/images/logo_dark.png'
                    : 'assets/images/logo_light.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Center(
                      child: Icon(
                        Icons.checkroom,
                        size: 28,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFB8956A)
                            : AppColors.primaryBrown,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        title: Text('ClothWise', style: Theme.of(context).textTheme.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.go(RoutePaths.profile);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              'Upload Your Photo',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              'Get personalized outfit recommendations',
              style: AppTextStyles.bodyRegular.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Gallery Option
            _UploadOption(
              icon: Icons.photo_library_outlined,
              title: 'Choose from Gallery',
              subtitle: 'Upload a photo from your device',
              onTap: _pickFromGallery,
              useAlternateColor: false,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Camera Option
            _UploadOption(
              icon: Icons.camera_alt_outlined,
              title: 'Scan with Camera',
              subtitle: 'Take a photo using your camera',
              onTap: _takePhoto,
              useAlternateColor: false,
            ),

            const SizedBox(height: AppSpacing.md),

            // Supported formats
            Text(
              'JPG, JPEG, PNG supported',
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Last Outfits Section
            const _LastOutfitsSection(),
          ],
        ),
      ),
    );
  }
}

/// Upload option card widget
class _UploadOption extends StatefulWidget {
  const _UploadOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.useAlternateColor = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool useAlternateColor;

  @override
  State<_UploadOption> createState() => _UploadOptionState();
}

class _UploadOptionState extends State<_UploadOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Button colors that change based on theme mode
    final cardColor = isDarkMode
        ? const Color(0xFFB8956A) // Gold in dark mode
        : const Color(0xFFFFFFFF); // White in light mode

    final blobAreaColor = isDarkMode
        ? const Color(0xFF1A1A1A) // Black in dark mode
        : const Color(0xFFEAE0D5); // Beige in light mode

    final titleColor = isDarkMode
        ? const Color(0xFF1A1A1A) // Dark text on gold in dark mode
        : AppColors.textPrimary; // Dark brown text in light mode

    final subtitleColor = isDarkMode
        ? const Color(0xFF2A2A2A) // Slightly lighter dark in dark mode
        : AppColors.textSecondary; // Medium brown in light mode

    final iconColor = isDarkMode
        ? const Color(0xFFFFFFFF) // White icon in dark mode
        : AppColors.primaryBrown; // Dark brown icon in light mode

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? AppColors.shadowMediumDark : AppColors.shadowMedium,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Multiple Animated Blobs Container
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: blobAreaColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: MultiBlobPainter(
                            animation: _controller,
                            color: isDarkMode
                                ? const Color(0xFFB8956A).withValues(alpha: 0.2) // Gold blobs in dark mode
                                : AppColors.primaryBrown.withValues(alpha: 0.1), // Brown blobs in light mode
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                    Center(
                      child: Icon(
                        widget.icon,
                        size: 40,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.title,
              style: AppTextStyles.h3.copyWith(
                color: titleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Last outfits section widget
class _LastOutfitsSection extends StatefulWidget {
  const _LastOutfitsSection();

  @override
  State<_LastOutfitsSection> createState() => _LastOutfitsSectionState();
}

class _LastOutfitsSectionState extends State<_LastOutfitsSection> {
  final OutfitStorageService _storageService = OutfitStorageService();
  List<Map<String, dynamic>> _outfits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    final outfits = await _storageService.getOutfitHistory();
    setState(() {
      _outfits = outfits;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              size: 20,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Last Outfits You Chose',
              style: theme.textTheme.headlineMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _outfits.isEmpty
                ? Container(
                    height: 210,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checkroom_outlined,
                          size: 48,
                          color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No saved outfits yet',
                          style: AppTextStyles.bodyRegular.copyWith(
                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Upload a photo and select items to create your first outfit',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _outfits.length,
                      itemBuilder: (context, index) {
                        final outfit = _outfits[index];
                        final imagePath = outfit['imagePath'] as String?;
                        final description = outfit['description'] as String? ?? 'My Outfit';
                        final selectedItems = outfit['selectedItems'] as List<dynamic>?;
                        final itemCount = selectedItems?.length ?? 0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => OutfitDetailScreen(outfit: outfit),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode ? AppColors.shadowMediumDark : AppColors.shadowMedium,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              // Image from uploaded photo
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppSpacing.cardRadius),
                                ),
                                child: imagePath != null && imagePath.isNotEmpty
                                    ? (imagePath.startsWith('http')
                                        ? Image.network(
                                            imagePath,
                                            height: 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildPlaceholder(isDarkMode);
                                            },
                                          )
                                        : Image.file(
                                            File(imagePath),
                                            height: 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildPlaceholder(isDarkMode);
                                            },
                                          ))
                                    : _buildPlaceholder(isDarkMode),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      description,
                                      style: AppTextStyles.itemName.copyWith(
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$itemCount items',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDarkMode) {
    return Container(
      height: 140,
      width: double.infinity,
      color: isDarkMode ? AppColors.borderLightDark : AppColors.borderLight,
      child: Center(
        child: Icon(
          Icons.checkroom,
          size: 48,
          color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// Custom painter for multiple animated blob shapes
class MultiBlobPainter extends CustomPainter {
  MultiBlobPainter({
    required this.animation,
    required this.color,
  });

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate opacity with fade in/out effect
    final t = animation.value;
    final opacity = _calculateOpacity(t);

    final paint = Paint()
      ..color = color.withValues(alpha: color.a * opacity)
      ..style = PaintingStyle.fill;

    // Define multiple blobs with different sizes and speeds
    final blobs = [
      _BlobConfig(
        startX: 0.2,
        startY: 0.3,
        radiusScale: 0.15,
        speedX: 1.0,
        speedY: 1.2,
        phase: 0.0,
      ),
      _BlobConfig(
        startX: 0.7,
        startY: 0.2,
        radiusScale: 0.12,
        speedX: -0.8,
        speedY: 1.5,
        phase: 2.0,
      ),
      _BlobConfig(
        startX: 0.5,
        startY: 0.7,
        radiusScale: 0.18,
        speedX: 1.3,
        speedY: -0.9,
        phase: 4.0,
      ),
      _BlobConfig(
        startX: 0.15,
        startY: 0.75,
        radiusScale: 0.1,
        speedX: -1.1,
        speedY: -1.0,
        phase: 1.5,
      ),
      _BlobConfig(
        startX: 0.8,
        startY: 0.65,
        radiusScale: 0.14,
        speedX: 0.9,
        speedY: -1.3,
        phase: 3.0,
      ),
      _BlobConfig(
        startX: 0.35,
        startY: 0.45,
        radiusScale: 0.11,
        speedX: -1.2,
        speedY: 1.1,
        phase: 5.0,
      ),
    ];

    for (final config in blobs) {
      _drawBlob(canvas, size, paint, config);
    }
  }

  // Calculate opacity with smooth fade in/out at loop boundaries
  double _calculateOpacity(double t) {
    const fadeLength = 0.15; // Fade over first/last 15% of animation

    if (t < fadeLength) {
      // Fade in at start
      return t / fadeLength;
    } else if (t > 1.0 - fadeLength) {
      // Fade out at end
      return (1.0 - t) / fadeLength;
    } else {
      // Full opacity in middle
      return 1.0;
    }
  }

  void _drawBlob(Canvas canvas, Size size, Paint paint, _BlobConfig config) {
    // Use smooth 0-1 animation value for seamless looping
    final t = animation.value;
    final time = t * 2 * math.pi;

    // Calculate moving position with smooth looping
    final centerX = size.width *
        (config.startX +
            0.15 * math.sin(time * config.speedX + config.phase));
    final centerY = size.height *
        (config.startY +
            0.15 * math.cos(time * config.speedY + config.phase));
    final center = Offset(centerX, centerY);

    final baseRadius = math.min(size.width, size.height) * config.radiusScale;

    final path = Path();

    // Create organic blob shape with smooth looping
    const points = 8;
    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * math.pi;

      // Add morphing variation with smoother frequencies
      final variation1 = math.sin(time * 2 + i + config.phase) * 0.15;
      final variation2 = math.cos(time * 3 + i * 1.2 + config.phase) * 0.1;
      final r = baseRadius * (1.0 + variation1 + variation2);

      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Smooth curves between points
        final prevAngle = ((i - 1) / points) * 2 * math.pi;
        final prevVariation1 = math.sin(time * 2 + (i - 1) + config.phase) * 0.15;
        final prevVariation2 =
            math.cos(time * 3 + (i - 1) * 1.2 + config.phase) * 0.1;
        final prevR = baseRadius * (1.0 + prevVariation1 + prevVariation2);

        final midAngle = (prevAngle + angle) / 2;
        final midR = (prevR + r) / 2 * 1.15;
        final cpX = center.dx + midR * math.cos(midAngle);
        final cpY = center.dy + midR * math.sin(midAngle);

        path.quadraticBezierTo(cpX, cpY, x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MultiBlobPainter oldDelegate) => true;
}

/// Configuration for individual blob
class _BlobConfig {
  _BlobConfig({
    required this.startX,
    required this.startY,
    required this.radiusScale,
    required this.speedX,
    required this.speedY,
    required this.phase,
  });

  final double startX;
  final double startY;
  final double radiusScale;
  final double speedX;
  final double speedY;
  final double phase;
}
