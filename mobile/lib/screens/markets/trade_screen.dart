import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/markets_service.dart';

class TradeScreen extends StatefulWidget {
  final String symbol;
  final String name;
  final double currentPrice;
  final String tradeType; // 'BUY' or 'SELL'
  final int? maxSellQuantity;
  final double availableBalance;

  const TradeScreen({
    super.key,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.tradeType,
    this.maxSellQuantity,
    required this.availableBalance,
  });

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final _quantityController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _quantity = 0;

  bool get isBuy => widget.tradeType.toUpperCase() == 'BUY';

  double get totalValue => _quantity * widget.currentPrice;

  int get maxBuyQuantity => widget.currentPrice > 0 ? (widget.availableBalance / widget.currentPrice).floor() : 0;

  int get maxQuantity => isBuy ? maxBuyQuantity : (widget.maxSellQuantity ?? 0);

  bool get canTrade => _quantity > 0 && _quantity <= maxQuantity;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(String value) {
    final qty = int.tryParse(value) ?? 0;
    setState(() {
      _quantity = qty;
      _errorMessage = null;
    });
  }

  void _setQuantity(int qty) {
    int finalQty = qty;
    if (finalQty > maxQuantity && maxQuantity > 0) {
      finalQty = maxQuantity;
    }
    
    _quantityController.text = finalQty.toString();
    setState(() {
      _quantity = finalQty;
      _errorMessage = null;
    });
  }

  void _setQuantityPercent(double percent) {
    if (maxQuantity <= 0) return;
    
    // Ensure percent is a finite number between 0 and 1
    final clampedPercent = percent.clamp(0.0, 1.0);
    // Calculate quantity, ensuring maxQuantity is positive before multiplication
    final qty = (maxQuantity > 0 && clampedPercent.isFinite ? maxQuantity * clampedPercent : 0.0).floor();
    _quantityController.text = qty.toString();
    setState(() {
      _quantity = qty;
      _errorMessage = null;
    });
  }

  Future<void> _executeTrade() async {
    if (!canTrade) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await MarketsService.executeTrade(
      symbol: widget.symbol,
      type: widget.tradeType,
      quantity: _quantity,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (response['success'] == true) {
        _showSuccessDialog(response['message'] ?? 'Trade executed successfully');
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to execute trade';
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final surfaceColor = isDark ? AppColorsDark.surface : Colors.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              isBuy ? '🎉 Purchase Successful!' : '✅ Sold Successfully!',
              style: AppTextStyles.heading3.copyWith(color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.body2.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'This is virtual money',
                    style: AppTextStyles.caption.copyWith(color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to stock detail
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isBuy ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final accentColor = isBuy ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.tradeType} ${widget.symbol}',
          style: AppTextStyles.heading3.copyWith(color: accentColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Virtual Money Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paper Trading: This is a simulation with virtual money. No real transactions.',
                      style: AppTextStyles.caption.copyWith(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stock Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            widget.symbol.substring(0, widget.symbol.length > 2 ? 2 : widget.symbol.length),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.symbol,
                              style: AppTextStyles.heading3.copyWith(color: textPrimary),
                            ),
                            Text(
                              widget.name,
                              style: AppTextStyles.caption.copyWith(color: textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Price',
                            style: AppTextStyles.caption.copyWith(color: textSecondary),
                          ),
                          Text(
                            '₹${widget.currentPrice.toStringAsFixed(2)}',
                            style: AppTextStyles.heading3.copyWith(color: textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Balance / Holdings Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isBuy ? Icons.account_balance_wallet : Icons.inventory_2,
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBuy ? 'Available Balance' : 'Shares Owned',
                          style: AppTextStyles.caption.copyWith(color: textSecondary),
                        ),
                        Text(
                          isBuy 
                              ? '₹${widget.availableBalance.toStringAsFixed(2)}'
                              : '${widget.maxSellQuantity ?? 0} shares',
                          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Max: $maxQuantity',
                    style: AppTextStyles.caption.copyWith(color: accentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quantity Input
            Text(
              'Enter Quantity',
              style: AppTextStyles.body1.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _errorMessage != null ? Colors.red : accentColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.heading2.copyWith(color: textPrimary),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppTextStyles.heading2.copyWith(color: textSecondary.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  suffixText: 'shares',
                  suffixStyle: AppTextStyles.body2.copyWith(color: textSecondary),
                ),
                onChanged: _updateQuantity,
              ),
            ),
            // Quick Select Buttons
            Text(
              'Quick Select',
              style: AppTextStyles.caption.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPercentButton('25%', 0.25, accentColor),
                const SizedBox(width: 8),
                _buildPercentButton('50%', 0.50, accentColor),
                const SizedBox(width: 8),
                _buildPercentButton('75%', 0.75, accentColor),
                const SizedBox(width: 8),
                _buildPercentButton('MAX', 1.0, accentColor),
              ],
            ),
            const SizedBox(height: 24),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Type', style: AppTextStyles.body2.copyWith(color: textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Market Order',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantity', style: AppTextStyles.body2.copyWith(color: textSecondary)),
                      Text('$_quantity shares', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Price', style: AppTextStyles.body2.copyWith(color: textSecondary)),
                      Text('₹${widget.currentPrice.toStringAsFixed(2)}', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBuy ? 'Total Cost' : 'Total Value',
                        style: AppTextStyles.body1.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${totalValue.toStringAsFixed(2)}',
                        style: AppTextStyles.heading3.copyWith(color: accentColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Execute Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canTrade && !_isLoading ? _executeTrade : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: accentColor.withOpacity(0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isBuy ? Icons.add_shopping_cart : Icons.sell),
                          const SizedBox(width: 8),
                          Text(
                            isBuy 
                                ? 'BUY ${widget.symbol}'
                                : 'SELL ${widget.symbol}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            Center(
              child: Text(
                '⚠️ Paper trading only - No real money involved',
                style: AppTextStyles.caption.copyWith(color: textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedQuantityButton(int qty, Color accentColor) {
    final bool isDisabled = maxQuantity <= 0;
    
    return Expanded(
      child: OutlinedButton(
        onPressed: isDisabled ? null : () => _setQuantity(qty),
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor.withOpacity(isDisabled ? 0.1 : 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPercentButton(String label, double percent, Color accentColor) {
    final bool isDisabled = maxQuantity <= 0;
    
    return Expanded(
      child: OutlinedButton(
        onPressed: isDisabled ? null : () => _setQuantityPercent(percent),
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor.withOpacity(isDisabled ? 0.1 : 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
