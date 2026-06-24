// lib/models/donation_models.dart
// OFG Connects — Creator Donation System Models

class CreatorWallet {
  final String creatorId;
  final double walletBalance;
  final double lifetimeDonations;
  final double lifetimePlatformFees;
  final int totalSupporters;
  final double monthlyEarnings;
  final double pendingPayout;
  final String lastPayoutDate;
  final String payoutAccount;
  final String updatedAt;

  const CreatorWallet({
    required this.creatorId,
    required this.walletBalance,
    required this.lifetimeDonations,
    required this.lifetimePlatformFees,
    required this.totalSupporters,
    required this.monthlyEarnings,
    required this.pendingPayout,
    required this.lastPayoutDate,
    required this.payoutAccount,
    required this.updatedAt,
  });

  factory CreatorWallet.fromJson(Map<String, dynamic> j) => CreatorWallet(
        creatorId: j['creator_id'] as String? ?? '',
        walletBalance: (j['wallet_balance'] as num?)?.toDouble() ?? 0,
        lifetimeDonations: (j['lifetime_donations'] as num?)?.toDouble() ?? 0,
        lifetimePlatformFees: (j['lifetime_platform_fees'] as num?)?.toDouble() ?? 0,
        totalSupporters: (j['total_supporters'] as num?)?.toInt() ?? 0,
        monthlyEarnings: (j['monthly_earnings'] as num?)?.toDouble() ?? 0,
        pendingPayout: (j['pending_payout'] as num?)?.toDouble() ?? 0,
        lastPayoutDate: j['last_payout_date'] as String? ?? '',
        payoutAccount: j['payout_account'] as String? ?? '',
        updatedAt: j['updated_at'] as String? ?? '',
      );

  bool get hasPayoutAccount => payoutAccount.isNotEmpty;
}

class PublicWallet {
  final int totalSupporters;
  final double lifetimeDonations;
  final double monthlyEarnings;

  const PublicWallet({
    required this.totalSupporters,
    required this.lifetimeDonations,
    required this.monthlyEarnings,
  });

  factory PublicWallet.fromJson(Map<String, dynamic> j) => PublicWallet(
        totalSupporters: (j['totalSupporters'] as num?)?.toInt() ?? 0,
        lifetimeDonations: (j['lifetimeDonations'] as num?)?.toDouble() ?? 0,
        monthlyEarnings: (j['monthlyEarnings'] as num?)?.toDouble() ?? 0,
      );
}

class Donation {
  final String id;
  final String donorId;
  final String creatorId;
  final double amount;
  final double platformFee;
  final double creatorAmount;
  final String message;
  final bool isAnonymous;
  final String status;
  final String transactionId;
  final String createdAt;
  final String? donorName;
  final String? donorAvatar;
  final String? creatorName;
  final String? creatorAvatar;

  const Donation({
    required this.id,
    required this.donorId,
    required this.creatorId,
    required this.amount,
    required this.platformFee,
    required this.creatorAmount,
    required this.message,
    required this.isAnonymous,
    required this.status,
    required this.transactionId,
    required this.createdAt,
    this.donorName,
    this.donorAvatar,
    this.creatorName,
    this.creatorAvatar,
  });

  factory Donation.fromJson(Map<String, dynamic> j) => Donation(
        id: j['id'] as String? ?? '',
        donorId: j['donor_id'] as String? ?? '',
        creatorId: j['creator_id'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        platformFee: (j['platform_fee'] as num?)?.toDouble() ?? 0,
        creatorAmount: (j['creator_amount'] as num?)?.toDouble() ?? 0,
        message: j['message'] as String? ?? '',
        isAnonymous: (j['is_anonymous'] as int? ?? 0) == 1,
        status: j['status'] as String? ?? 'completed',
        transactionId: j['transaction_id'] as String? ?? '',
        createdAt: j['created_at'] as String? ?? '',
        donorName: j['donor_name'] as String?,
        donorAvatar: j['donor_avatar'] as String?,
        creatorName: j['creator_name'] as String?,
        creatorAvatar: j['creator_avatar'] as String?,
      );
}

class Payout {
  final String id;
  final String creatorId;
  final double amount;
  final String status;
  final String requestedAt;
  final String approvedAt;
  final String paidAt;
  final String rejectionReason;
  final String? creatorName;
  final String? creatorEmail;
  final String? payoutAccount;

  const Payout({
    required this.id,
    required this.creatorId,
    required this.amount,
    required this.status,
    required this.requestedAt,
    required this.approvedAt,
    required this.paidAt,
    required this.rejectionReason,
    this.creatorName,
    this.creatorEmail,
    this.payoutAccount,
  });

  factory Payout.fromJson(Map<String, dynamic> j) => Payout(
        id: j['id'] as String? ?? '',
        creatorId: j['creator_id'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'pending',
        requestedAt: j['requested_at'] as String? ?? '',
        approvedAt: j['approved_at'] as String? ?? '',
        paidAt: j['paid_at'] as String? ?? '',
        rejectionReason: j['rejection_reason'] as String? ?? '',
        creatorName: j['creator_name'] as String?,
        creatorEmail: j['creator_email'] as String?,
        payoutAccount: j['payout_account'] as String?,
      );
}
