import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/hive_service.dart';

class OnboardingSlideshowScreen extends StatefulWidget {
  const OnboardingSlideshowScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingSlideshowScreen> createState() => _OnboardingSlideshowScreenState();
}

class _OnboardingSlideshowScreenState extends State<OnboardingSlideshowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_SlideData> _slides = [
    _SlideData(
      emoji: '📈',
      title: 'Welcome to GrowLog!',
      description:
          'Your personal learning & growth companion.\nTrack your daily progress and build habits that stick.',
    ),
    _SlideData(
      emoji: '✏️',
      title: 'Daily Check-ins',
      description:
          'Log what you learn every day with quick study or work check-ins.\nCapture study hours, mood, and reflections in seconds.',
    ),
    _SlideData(
      emoji: '🎯',
      title: 'Goals & Streaks',
      description:
          'Set learning goals and build streaks to stay consistent.\nWatch your streak grow as you check in daily!',
    ),
    _SlideData(
      emoji: '📊',
      title: 'Progress Tracking',
      description:
          'Visualize your growth with charts, weekly reviews,\nand monthly summaries. See how far you\'ve come!',
    ),
    _SlideData(
      emoji: '👨‍👧',
      title: 'Multi-Profile Support',
      description:
          'Switch between Student & Professional modes.\nShare the device with family — each profile keeps its own data!',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    await HiveService.setOnboardingSeen();
    if (mounted) {
      context.goNamed('modeSelection');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBg = Color(0xFFFAF7F0);
    const deepTeal = Color(0xFF085041);
    const mutedText = Color(0xFF7C7567);

    return Scaffold(
      backgroundColor: primaryBg,
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildSlide(_slides[index]);
            },
          ),

          // Skip button (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _currentPage < _slides.length - 1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _currentPage < _slides.length - 1
                    ? _finishOnboarding
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: deepTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

          // Bottom controls (dots + button)
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? deepTeal
                            : deepTeal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Next / Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started 🚀'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildSlide(_SlideData slide) {
    const primaryBg = Color(0xFFFAF7F0);
    const deepTeal = Color(0xFF085041);
    const lightTeal = Color(0xFFE1F5EE);
    const darkText = Color(0xFF04342C);
    const mutedText = Color(0xFF7C7567);

    return Container(
      color: primaryBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Emoji icon with clean light teal container
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightTeal,
                ),
                child: Center(
                  child: Text(
                    slide.emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Title
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500, // medium weight
                  color: darkText,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: mutedText,
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final String emoji;
  final String title;
  final String description;

  const _SlideData({
    required this.emoji,
    required this.title,
    required this.description,
  });
}
