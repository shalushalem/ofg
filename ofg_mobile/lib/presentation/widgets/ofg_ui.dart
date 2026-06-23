// lib/presentation/widgets/ofg_ui.dart
import 'package:flutter/material.dart';
import '../theme/ofg_theme.dart';

class OfgPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OfgPrimaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class OfgOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OfgOutlineButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFCCCCCC),
          side: const BorderSide(color: kBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class OfgInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboard;

  const OfgInput({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: kMuted2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
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
      ),
    );
  }
}

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

class OfgBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const OfgBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
    );
  }
}

// A simple global helper for that nice panel look you use everywhere
BoxDecoration ofgPanelDecoration({double radius = 12, Color color = kPanel}) {
  return BoxDecoration(
    color: color,
    border: Border.all(color: kBorder),
    borderRadius: BorderRadius.circular(radius),
  );
}