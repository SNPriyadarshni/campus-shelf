import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';

class RatingPage extends StatefulWidget {
  final ItemModel item;

  const RatingPage({super.key, required this.item});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage>
    with TickerProviderStateMixin {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  late AnimationController _starController;
  late List<AnimationController> _starAnimControllers;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _starAnimControllers = List.generate(
      5,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _starController.dispose();
    for (var c in _starAnimControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onStarTap(int index) {
    setState(() => _selectedRating = index + 1);
    // Animate the tapped star
    _starAnimControllers[index].forward(from: 0.0);
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate submission
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });

    // Navigate back to home after showing thank you
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _getRatingLabel() {
    switch (_selectedRating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap a star to rate';
    }
  }

  String _getRatingEmoji() {
    switch (_selectedRating) {
      case 1:
        return '😞';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😄';
      case 5:
        return '🤩';
      default:
        return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neonGreen = const Color(0xFF00E676);

    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: neonGreen.withOpacity(0.15),
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps us improve.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Returning to home...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rate Your Experience'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Emoji + Label ───────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _getRatingEmoji(),
                key: ValueKey(_selectedRating),
                style: const TextStyle(fontSize: 64),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _getRatingLabel(),
                key: ValueKey(_selectedRating),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color:
                      _selectedRating > 0 ? neonGreen : Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How was your purchase of "${widget.item.name}"?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),

            // ── Star Rating ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final isActive = index < _selectedRating;
                return GestureDetector(
                  onTap: () => _onStarTap(index),
                  child: AnimatedBuilder(
                    animation: _starAnimControllers[index],
                    builder: (context, child) {
                      final bounce = 1.0 +
                          0.3 *
                              (1.0 - (_starAnimControllers[index].value - 0.5).abs() * 2)
                                  .clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: _starAnimControllers[index].isAnimating
                            ? bounce
                            : 1.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? neonGreen.withOpacity(0.15)
                                  : Colors.grey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive
                                    ? neonGreen
                                    : Colors.grey.withOpacity(0.2),
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 30,
                              color: isActive ? neonGreen : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 36),

            // ── Feedback Text Field ─────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ── Submit Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonGreen,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: neonGreen.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Skip ────────────────────────────────────────────
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
