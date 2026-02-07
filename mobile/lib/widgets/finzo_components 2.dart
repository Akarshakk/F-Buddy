import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Instagram-inspired card component with clean styling
class FinzoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool hasBorder;
  final bool hasShadow;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const FinzoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.hasBorder = true,
    this.hasShadow = false,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(FinzoRadius.lg);
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? FinzoTheme.surface(context),
        borderRadius: radius,
        border: hasBorder ? Border.all(
          color: FinzoTheme.border(context),
          width: 0.5,
        ) : null,
        boxShadow: hasShadow ? FinzoShadows.sm(context) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(FinzoSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Summary stat card (for dashboard)
class FinzoStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const FinzoStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FinzoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? FinzoTheme.brandAccent(context)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(FinzoRadius.md),
            ),
            child: Icon(
              icon,
              color: iconColor ?? FinzoTheme.brandAccent(context),
              size: 20,
            ),
          ),
          const SizedBox(height: FinzoSpacing.md),
          Text(
            label,
            style: FinzoTypography.labelMedium(),
          ),
          const SizedBox(height: FinzoSpacing.xs),
          Text(
            value,
            style: FinzoTypography.amountMedium().copyWith(
              color: valueColor ?? FinzoTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Transaction/expense item row
class FinzoListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const FinzoListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FinzoSpacing.lg,
          vertical: FinzoSpacing.md,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: FinzoSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FinzoTypography.titleMedium(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: FinzoTypography.bodySmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: FinzoTypography.titleMedium().copyWith(
                  color: trailingColor ?? FinzoTheme.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Category icon with circular background
class FinzoCategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const FinzoCategoryIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.5,
      ),
    );
  }
}

/// Primary action button (Instagram blue style)
class FinzoPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const FinzoPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: FinzoTheme.buttonPrimary(context),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinzoRadius.md),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: FinzoTypography.button(),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary/outline button
class FinzoSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final IconData? icon;

  const FinzoSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: FinzoTheme.textPrimary(context),
          side: BorderSide(color: FinzoTheme.border(context)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinzoRadius.md),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: FinzoTypography.button().copyWith(
                color: FinzoTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Instagram-style text field
class FinzoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;

  const FinzoTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: FinzoTypography.labelLarge(),
          ),
          const SizedBox(height: FinzoSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          style: FinzoTypography.bodyMedium(),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: FinzoTheme.textSecondary(context))
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Section header with optional action button
class FinzoSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const FinzoSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FinzoSpacing.lg,
        vertical: FinzoSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: FinzoTypography.headlineSmall(),
          ),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionText!,
                style: FinzoTypography.labelMedium().copyWith(
                  color: FinzoTheme.brandAccent(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty state placeholder
class FinzoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const FinzoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FinzoSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(FinzoSpacing.xl),
              decoration: BoxDecoration(
                color: FinzoTheme.surfaceVariant(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: FinzoTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: FinzoSpacing.xl),
            Text(
              title,
              style: FinzoTypography.headlineMedium(),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: FinzoSpacing.sm),
              Text(
                subtitle!,
                style: FinzoTypography.bodyMedium().copyWith(
                  color: FinzoTheme.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null) ...[
              const SizedBox(height: FinzoSpacing.xl),
              FinzoPrimaryButton(
                text: actionText!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet header
class FinzoBottomSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const FinzoBottomSheetHeader({
    super.key,
    required this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: FinzoSpacing.sm),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: FinzoTheme.textTertiary(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(FinzoSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: FinzoTypography.headlineMedium(),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close,
                    color: FinzoTheme.textPrimary(context),
                  ),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: FinzoTheme.divider(context)),
      ],
    );
  }
}

/// Balance display card
class FinzoBalanceCard extends StatelessWidget {
  final String title;
  final String balance;
  final String? subtitle;
  final List<FinzoBalanceItem>? items;

  const FinzoBalanceCard({
    super.key,
    required this.title,
    required this.balance,
    this.subtitle,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FinzoSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FinzoTheme.brandAccent(context),
            FinzoTheme.brandAccent(context).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(FinzoRadius.xl),
        boxShadow: [
          BoxShadow(
            color: FinzoTheme.brandAccent(context).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: FinzoTypography.labelMedium().copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: FinzoSpacing.xs),
          Text(
            balance,
            style: FinzoTypography.amountLarge().copyWith(
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: FinzoSpacing.xs),
            Text(
              subtitle!,
              style: FinzoTypography.bodySmall().copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
          if (items != null && items!.isNotEmpty) ...[
            const SizedBox(height: FinzoSpacing.lg),
            Row(
              children: items!.map((item) => Expanded(
                child: _buildBalanceItem(context, item),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceItem(BuildContext context, FinzoBalanceItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: FinzoTypography.labelSmall().copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: FinzoTypography.titleMedium(color: Colors.white).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class FinzoBalanceItem {
  final String label;
  final String value;
  final Color color;

  const FinzoBalanceItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Chip/Tag component
class FinzoChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;

  const FinzoChip({
    super.key,
    required this.label,
    this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? FinzoTheme.brandAccent(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FinzoSpacing.md,
          vertical: FinzoSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(FinzoRadius.full),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: FinzoTypography.labelMedium(
            color: isSelected ? Colors.white : chipColor,
          ).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
