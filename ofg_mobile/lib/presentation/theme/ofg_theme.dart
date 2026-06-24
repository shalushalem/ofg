// lib/presentation/theme/ofg_theme.dart
import 'package:flutter/material.dart';

// ─── Color palette ────────────────────────────────────────────────────────────
const Color kBg       = Color(0xFF000000);
const Color kPanel    = Color(0xFF101010);
const Color kPanel2   = Color(0xFF161616);
const Color kBorder   = Color(0xFF242424);
const Color kMuted    = Color(0xFF7C7C7C);
const Color kMuted2   = Color(0xFF4E4E4E);
const Color kAccent   = Color(0xFFFF4438);
const Color kAccentSoft = Color(0xFFFF6B61);

// ─── Categories ───────────────────────────────────────────────────────────────
const List<String> kCategories = [
  'For You',
  'Sermons',
  'Worship',
  'Prayer',
  'Testimony',
  'Bible Study',
  'Kids',
  'Youth',
  'Live',
];

/// Maps display label → API parameter value
const Map<String, String?> kCategoryApiMap = {
  'For You':     null,
  'Sermons':     'sermons',
  'Worship':     'worship',
  'Prayer':      'prayer',
  'Testimony':   'testimony',
  'Bible Study': 'bible_study',
  'Kids':        'kids',
  'Youth':       'youth',
  'Live':        'live',
};

// ─── API Base ──────────────────────────────────────────────────────────────────
const String kDefaultApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://ofg-connects-production.up.railway.app',
);

// Admin secret (matches backend ADMIN_SECRET env var)
const String kAdminSecret = 'ofg_admin_2024';