import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/item_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'rating_page.dart';

class PaymentPage extends StatefulWidget {
  final ItemModel item;

  const PaymentPage({super.key, required this.item});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  int _selectedMethod = -1; // -1 = none selected
  bool _isProcessing = false;
  bool _isSuccess = false;

  late AnimationController _successController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'icon': Icons.account_balance,
      'title': 'UPI',
      'subtitle': 'Google Pay, PhonePe, Paytm',
    },
    {
      'icon': Icons.credit_card,
      'title': 'Card',
      'subtitle': 'Credit / Debit Card',
    },
    {
      'icon': Icons.handshake_outlined,
      'title': 'Cash on Meetup',
      'subtitle': 'Pay when you collect',
    },
  ];

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    // Auto‑process free items: skip payment UI and directly mark as sold
    if (widget.item.priceType == 'Free') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processFreePurchase();
      });
    }
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  Future<void> _processFreePurchase() async {
    // No payment method needed, directly mark as sold
    setState(() => _isProcessing = true);
    try {
      final buyerEmail = AuthService().currentUser?.email ?? '';
      await ApiService.updateItemStatus(widget.item.id, 'sold', buyerEmail: buyerEmail);
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
      _successController.forward();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RatingPage(item: widget.item)),
        );
      }
    } catch (e) {
      debugPrint('Error updating item status: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        _showErrorDialog(e.toString().contains('sold') 
          ? 'This item was just sold to someone else!' 
          : 'Failed to complete purchase. Please try again.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purchase Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to details page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a payment method'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Mark item as sold in the backend
    try {
      final buyerEmail = AuthService().currentUser?.email ?? '';
      await ApiService.updateItemStatus(widget.item.id, 'sold', buyerEmail: buyerEmail);
      
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });

      _successController.forward();

      // Navigate to rating page after success animation
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RatingPage(item: widget.item),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating item status: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        _showErrorDialog(e.toString().contains('sold') 
          ? 'This item was just sold to someone else!' 
          : 'Failed to complete purchase. Please try again.');
      }
    }
  }

  String _getItemPrice() {
    if (widget.item.priceType == 'Free') return 'FREE';
    // Extract number from priceType if it contains one, otherwise show as-is
    final priceMatch = RegExp(r'\d+').firstMatch(widget.item.priceType);
    if (priceMatch != null) {
      return '₹${priceMatch.group(0)}';
    }
    return widget.item.priceType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neonGreen = const Color(0xFF00E676);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _isSuccess
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF1E1E1E) 
                  : const Color(0xFF212121),
              foregroundColor: Colors.white,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              title: const Text('Payment'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: _isSuccess ? _buildSuccessView(neonGreen) : _buildPaymentView(theme, neonGreen),
    );
  }

  Widget _buildSuccessView(Color neonGreen) {
    return Center(
      child: AnimatedBuilder(
        animation: _successController,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: neonGreen.withOpacity(0.15),
                    border: Border.all(color: neonGreen, width: 3),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 60 * _checkAnimation.value,
                    color: neonGreen,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Opacity(
                opacity: _checkAnimation.value,
                child: const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: _checkAnimation.value,
                child: Text(
                  'Redirecting to feedback...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentView(ThemeData theme, Color neonGreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Item Summary Card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                // Item image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: widget.item.imageUrl.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(widget.item.imageUrl.split(',')[1]),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderIcon(),
                          )
                        : widget.item.imageUrl
                                .startsWith('https://via.placeholder.com')
                            ? _placeholderIcon()
                            : Image.network(
                                widget.item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderIcon(),
                              ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: neonGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getItemPrice(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: neonGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Payment Method Section ────────────────────────────
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(_paymentMethods.length, (index) {
            final method = _paymentMethods[index];
            final isSelected = _selectedMethod == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? neonGreen : theme.dividerColor.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: neonGreen.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? neonGreen.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      method['icon'],
                      color: isSelected ? neonGreen : Colors.grey.shade500,
                    ),
                  ),
                  title: Text(
                    method['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected ? neonGreen : null,
                    ),
                  ),
                  subtitle: Text(
                    method['subtitle'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  trailing: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? neonGreen : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? neonGreen : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.black)
                        : null,
                  ),
                  onTap: () => setState(() => _selectedMethod = index),
                ),
              ),
            );
          }),
          const SizedBox(height: 32),

          // ── Order Summary ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _summaryRow('Item', widget.item.name),
                const SizedBox(height: 8),
                _summaryRow('Condition', widget.item.condition),
                const SizedBox(height: 8),
                _summaryRow('Seller', widget.item.postedBy),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                _summaryRow('Total', _getItemPrice(), isBold: true, isGreen: true),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Pay Now Button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: neonGreen,
                foregroundColor: Colors.black,
                disabledBackgroundColor: neonGreen.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Security note ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Secure & Encrypted Payment',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade500,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isGreen ? const Color(0xFF00E676) : null,
          ),
        ),
      ],
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          widget.item.category == 'Book' ? Icons.book : Icons.edit,
          size: 30,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
