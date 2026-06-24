import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../../api/api_client.dart';
import '../../logic/providers.dart';
import '../../models/donation_models.dart';

final donationHistoryProvider = FutureProvider.autoDispose<List<Donation>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.getDonationHistory(page: 0);
  final items = data['items'] as List? ?? [];
  return items.map((e) => Donation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

class DonationHistoryPage extends ConsumerWidget {
  const DonationHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(donationHistoryProvider);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('My Donations', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: histAsync.when(
        data: (donations) {
          if (donations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, color: kMuted, size: 56),
                  SizedBox(height: 16),
                  Text('No donations yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text(
                    'Support a creator or ministry\nto see your history here.',
                    style: TextStyle(color: kMuted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          double total = donations.fold(0, (s, d) => s + d.amount);

          return Column(
            children: [
              // Total summary
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.pinkAccent, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Donated', style: TextStyle(color: kMuted, fontSize: 13)),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Ministries', style: TextStyle(color: kMuted, fontSize: 13)),
                        Text(
                          '${donations.map((d) => d.creatorId).toSet().length}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: donations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final d = donations[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: ofgPanelDecoration(),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: kPanel2,
                            backgroundImage: (d.creatorAvatar?.isNotEmpty == true)
                                ? NetworkImage(d.creatorAvatar!)
                                : null,
                            child: (d.creatorAvatar?.isNotEmpty != true)
                                ? Text(
                                    (d.creatorName?.isNotEmpty == true) ? d.creatorName![0].toUpperCase() : '?',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.creatorName ?? 'Creator',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (d.message.isNotEmpty)
                                  Text('"${d.message}"',
                                      style: const TextStyle(color: kMuted, fontSize: 12),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                Row(
                                  children: [
                                    Text(
                                      d.createdAt.length >= 10 ? d.createdAt.substring(0, 10) : d.createdAt,
                                      style: const TextStyle(color: kMuted, fontSize: 11),
                                    ),
                                    if (d.isAnonymous) ...[
                                      const SizedBox(width: 8),
                                      const Text('• Anonymous', style: TextStyle(color: kMuted, fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${d.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  d.status.toUpperCase(),
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
        error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: kMuted))),
      ),
    );
  }
}
