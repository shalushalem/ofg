import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../../api/api_client.dart';
import '../../logic/providers.dart';
import '../../models/donation_models.dart';


// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _walletProvider = FutureProvider.autoDispose<CreatorWallet>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.getCreatorWallet();
  return CreatorWallet.fromJson(data);
});

final _creatorDonationsProvider = FutureProvider.autoDispose<List<Donation>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.getCreatorDonations(page: 0);
  final items = data['items'] as List? ?? [];
  return items.map((e) => Donation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

final _creatorPayoutsProvider = FutureProvider.autoDispose<List<Payout>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.getCreatorPayouts(page: 0);
  final items = data['items'] as List? ?? [];
  return items.map((e) => Payout.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

// ---------------------------------------------------------------------------
// Creator Earnings Page
// ---------------------------------------------------------------------------

class CreatorEarningsPage extends ConsumerStatefulWidget {
  const CreatorEarningsPage({super.key});

  @override
  ConsumerState<CreatorEarningsPage> createState() => _CreatorEarningsPageState();
}

class _CreatorEarningsPageState extends ConsumerState<CreatorEarningsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Earnings Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: kAccent,
          labelColor: kAccent,
          unselectedLabelColor: kMuted,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Donations'),
            Tab(text: 'Payouts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OverviewTab(),
          _DonationsTab(),
          _PayoutsTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(_walletProvider);

    return walletAsync.when(
      data: (w) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: kAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text('Available Balance', style: TextStyle(color: kMuted, fontSize: 13)),
                      const Spacer(),
                      if (w.pendingPayout > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '₹${w.pendingPayout.toStringAsFixed(0)} pending',
                            style: const TextStyle(color: Colors.orange, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${w.walletBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Withdraw button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: w.walletBalance >= 500
                          ? () => _showPayoutSheet(context, w)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        disabledBackgroundColor: kPanel2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                      label: Text(
                        w.walletBalance >= 500
                            ? 'Request Payout'
                            : 'Min ₹500 to withdraw',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                  icon: Icons.favorite,
                  iconColor: Colors.pinkAccent,
                  label: 'Total Received',
                  value: '₹${w.lifetimeDonations.toStringAsFixed(0)}',
                ),
                _StatCard(
                  icon: Icons.people,
                  iconColor: Colors.blueAccent,
                  label: 'Supporters',
                  value: w.totalSupporters.toString(),
                ),
                _StatCard(
                  icon: Icons.calendar_month,
                  iconColor: Colors.greenAccent,
                  label: 'This Month',
                  value: '₹${w.monthlyEarnings.toStringAsFixed(0)}',
                ),
                _StatCard(
                  icon: Icons.bar_chart,
                  iconColor: Colors.orangeAccent,
                  label: 'Platform Fees',
                  value: '₹${w.lifetimePlatformFees.toStringAsFixed(0)}',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Payout account section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ofgPanelDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payout Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  if (w.hasPayoutAccount) ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(w.payoutAccount, style: const TextStyle(color: kMuted, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showPayoutAccountDialog(context, ref),
                      child: const Text('Change Account', style: TextStyle(color: kAccent, fontSize: 13)),
                    ),
                  ] else ...[
                    const Text(
                      'Connect your UPI ID or bank account to receive payouts.',
                      style: TextStyle(color: kMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showPayoutAccountDialog(context, ref),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.link, color: kAccent, size: 18),
                        label: const Text('Connect Payout Account', style: TextStyle(color: kAccent)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (w.lastPayoutDate.isNotEmpty)
              Text(
                'Last payout: ${w.lastPayoutDate.substring(0, 10)}',
                style: const TextStyle(color: kMuted, fontSize: 12),
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
      error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: kMuted))),
    );
  }

  void _showPayoutSheet(BuildContext context, CreatorWallet wallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PayoutRequestSheet(wallet: wallet),
    );
  }

  void _showPayoutAccountDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Connect Payout Account'),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'yourname@upi or account@bank',
            hintStyle: TextStyle(color: kMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final account = ctrl.text.trim();
              if (account.isEmpty) return;
              Navigator.pop(context);
              try {
                await ref.read(apiClientProvider).updatePayoutAccount(account);
                ref.invalidate(_walletProvider);
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: kAccent),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Donations Tab
// ---------------------------------------------------------------------------

class _DonationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(_creatorDonationsProvider);

    return donationsAsync.when(
      data: (donations) {
        if (donations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, color: kMuted, size: 48),
                SizedBox(height: 12),
                Text('No donations yet', style: TextStyle(color: kMuted, fontSize: 16)),
                SizedBox(height: 4),
                Text('Share your content to grow your support!',
                    style: TextStyle(color: kMuted, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _DonationCard(donation: donations[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
      error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: kMuted))),
    );
  }
}

// ---------------------------------------------------------------------------
// Payouts Tab
// ---------------------------------------------------------------------------

class _PayoutsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(_creatorPayoutsProvider);

    return payoutsAsync.when(
      data: (payouts) {
        if (payouts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance, color: kMuted, size: 48),
                SizedBox(height: 12),
                Text('No payouts yet', style: TextStyle(color: kMuted, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payouts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _PayoutCard(payout: payouts[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
      error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: kMuted))),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget helpers
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ofgPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Donation donation;
  const _DonationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    final name = donation.isAnonymous ? 'Anonymous Supporter' : (donation.donorName ?? 'Unknown');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ofgPanelDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: kPanel2,
            child: donation.isAnonymous
                ? const Icon(Icons.person_outline, color: kMuted)
                : Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (donation.message.isNotEmpty)
                  Text('"${donation.message}"',
                      style: const TextStyle(color: kMuted, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  donation.createdAt.length >= 10 ? donation.createdAt.substring(0, 10) : donation.createdAt,
                  style: const TextStyle(color: kMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${donation.creatorAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent)),
              Text('of ₹${donation.amount.toStringAsFixed(0)}',
                  style: const TextStyle(color: kMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  final Payout payout;
  const _PayoutCard({required this.payout});

  Color get _statusColor {
    switch (payout.status) {
      case 'paid': return Colors.greenAccent;
      case 'approved': return Colors.blueAccent;
      case 'rejected': return Colors.redAccent;
      default: return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ofgPanelDecoration(),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_upward, color: _statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${payout.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  payout.requestedAt.length >= 10 ? 'Requested ${payout.requestedAt.substring(0, 10)}' : '',
                  style: const TextStyle(color: kMuted, fontSize: 12),
                ),
                if (payout.rejectionReason.isNotEmpty)
                  Text(payout.rejectionReason, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(payout.status.toUpperCase(),
                style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payout Request Bottom Sheet
// ---------------------------------------------------------------------------

class _PayoutRequestSheet extends ConsumerStatefulWidget {
  final CreatorWallet wallet;
  const _PayoutRequestSheet({required this.wallet});

  @override
  ConsumerState<_PayoutRequestSheet> createState() => _PayoutRequestSheetState();
}

class _PayoutRequestSheetState extends ConsumerState<_PayoutRequestSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.wallet.walletBalance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_ctrl.text.trim());
    if (amount == null || amount < 500) {
      setState(() => _error = 'Minimum payout is ₹500');
      return;
    }
    if (amount > widget.wallet.walletBalance) {
      setState(() => _error = 'Insufficient balance');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(apiClientProvider).requestPayout(amount);
      ref.invalidate(_walletProvider);
      ref.invalidate(_creatorPayoutsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout request submitted! Admin will review within 2–3 days.')),
      );
    } on ApiException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Request Payout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Available: ₹${widget.wallet.walletBalance.toStringAsFixed(2)}',
              style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(color: kAccent, fontSize: 20, fontWeight: FontWeight.bold),
              hintText: 'Amount (min ₹500)',
              hintStyle: const TextStyle(color: kMuted),
              filled: true,
              fillColor: kPanel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kAccent),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Text('Payout to: ${widget.wallet.payoutAccount}',
              style: const TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Payout Request', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
