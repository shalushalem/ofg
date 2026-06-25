// lib/presentation/widgets/ofg_ui.dart
import 'package:flutter/material.dart';
import '../theme/ofg_theme.dart';

// ─── Primary Button ────────────────────────────────────────────────────────────
class OfgPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const OfgPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white30,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black54,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
      ),
    );
  }
}

// ─── Outline Button ────────────────────────────────────────────────────────────
class OfgOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const OfgOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? const Color(0xFFCCCCCC),
          side: BorderSide(color: color?.withValues(alpha: 0.5) ?? kBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ─── Text Input ────────────────────────────────────────────────────────────────
class OfgInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboard;
  final String? hint;
  final Widget? suffix;
  final VoidCallback? onTap;
  final bool readOnly;

  const OfgInput({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboard,
    this.hint,
    this.suffix,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboard,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: kMuted2),
        labelStyle: const TextStyle(
          color: kMuted2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: kPanel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kAccent, width: 1.4),
          borderRadius: BorderRadius.circular(14),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kBorder),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ─── OFG Logo ──────────────────────────────────────────────────────────────────
class OfgLogo extends StatelessWidget {
  final double size;
  final bool connects;
  final bool premium;
  final bool dark;

  const OfgLogo({
    super.key,
    required this.size,
    this.connects = true,
    this.premium = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = dark ? Colors.black : Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'OFG',
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0,
          ),
        ),
        Container(
          width: size * 0.23,
          height: size * 0.23,
          margin: EdgeInsets.only(
            left: 2,
            right: connects ? 6 : 0,
            bottom: size * 0.16,
          ),
          decoration: const BoxDecoration(
            color: kAccent,
            shape: BoxShape.circle,
          ),
        ),
        if (connects)
          Text(
            premium ? 'Premium' : 'CONNECTS',
            style: TextStyle(
              color: premium ? Colors.white : kMuted,
              fontSize: premium ? size : size * 0.34,
              fontWeight: FontWeight.w900,
              letterSpacing: premium ? 0 : 3,
            ),
          ),
      ],
    );
  }
}

// ─── Back Button ──────────────────────────────────────────────────────────────
class OfgBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const OfgBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: kPanel,
          shape: BoxShape.circle,
          border: Border.all(color: kBorder),
        ),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
      ),
    );
  }
}

// ─── Verified Badge ───────────────────────────────────────────────────────────
class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1DA1F2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, color: Colors.white, size: size * 0.65),
    );
  }
}

// ─── Creator Avatar ───────────────────────────────────────────────────────────
class CreatorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final bool verified;

  const CreatorAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.radius = 20,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: kPanel2,
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
          child: hasAvatar
              ? null
              : Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'O',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: radius * 0.9,
                  ),
                ),
        ),
        if (verified)
          Positioned(
            right: 0,
            bottom: 0,
            child: VerifiedBadge(size: radius * 0.7),
          ),
      ],
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class OfgStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const OfgStatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kPanel,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? kMuted, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? leading;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class OfgEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const OfgEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kMuted2, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted, fontSize: 13, height: 1.5),
              ),
            ],
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: 24),
              OfgOutlineButton(label: buttonLabel!, onTap: onButton!),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Settings Row ─────────────────────────────────────────────────────────────
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;
  final Widget? trailing;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.iconColor,
    this.labelColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF111111))),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: labelColor ?? Colors.white,
                ),
              ),
            ),
            if (value != null)
              Text(value!, style: const TextStyle(color: kMuted, fontSize: 13)),
            if (trailing != null) trailing!,
            if (onTap != null)
              const Icon(Icons.chevron_right, color: kMuted2, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Panel Decoration Helper ──────────────────────────────────────────────────
BoxDecoration ofgPanelDecoration({double radius = 12, Color color = kPanel}) {
  return BoxDecoration(
    color: color,
    border: Border.all(color: kBorder),
    borderRadius: BorderRadius.circular(radius),
  );
}