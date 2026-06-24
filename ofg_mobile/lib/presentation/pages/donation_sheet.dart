import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ofg_theme.dart';
import '../../api/api_client.dart';
import '../../logic/providers.dart';

// Quick-select donation amounts in INR
const _kAmounts = [10.0, 50.0, 100.0, 250.0, 500.0, 1000.0];

class DonationSheet extends ConsumerStatefulWidget {
  final String creatorId;
  final String creatorName;
  final String creatorAvatar;

  const DonationSheet({
    super.key,
    required this.creatorId,
    required this.creatorName,
    required this.creatorAvatar,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String creatorId,
    required String creatorName,
    String creatorAvatar = '',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DonationSheet(
        creatorId: creatorId,
        creatorName: creatorName,
        creatorAvatar: creatorAvatar,
      ),
    );
  }

  @override
  ConsumerState<DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends ConsumerState<DonationSheet> {
  double? _selectedAmount;
  bool _customMode = false;
  final _customCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isAnonymous = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _customCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  double? get _effectiveAmount {
    if (_customMode) {
      final v = double.tryParse(_customCtrl.text.trim());
      return v;
    }
    return _selectedAmount;
  }

  bool get _valid {
    final a = _effectiveAmount;
    return a != null && a >= 10 && a <= 50000;
  }

  Future<void> _submit() async {
    final amount = _effectiveAmount;
    if (amount == null || !_valid) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiClientProvider);
      final result = await api.donate(
        creatorId: widget.creatorId,
        amount: amount,
        message: _messageCtrl.text.trim(),
        isAnonymous: _isAnonymous,
      );
      if (!mounted) return;
      // Invalidate wallet so creator studio refreshes
      ref.invalidate(creatorStatsProvider);
      Navigator.pop(context, true);
      _showSuccess(context, result, amount);
    } on ApiException catch (e) {
      setState(() { _error = e.message; });
    } catch (e) {
      setState(() { _error = 'Something went wrong. Please try again.' ; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _showSuccess(BuildContext ctx, Map<String, dynamic> result, double amount) {
    showDialog(
      context: ctx,
      builder: (_) => _DonationSuccessDialog(
        amount: amount,
        creatorName: result['creatorName'] as String? ?? widget.creatorName,
        transactionId: result['transactionId'] as String? ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.only(top: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                _Avatar(name: widget.creatorName, avatarUrl: widget.creatorAvatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support ${widget.creatorName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Support their ministry with a donation 🙏',
                        style: TextStyle(color: kMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text('Select Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kMuted)),
            const SizedBox(height: 10),

            // Quick amounts grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: [
                ..._kAmounts.map((a) => _AmountChip(
                  label: '₹${a.toInt()}',
                  selected: !_customMode && _selectedAmount == a,
                  onTap: () => setState(() { _selectedAmount = a; _customMode = false; }),
                )),
                _AmountChip(
                  label: 'Custom',
                  selected: _customMode,
                  onTap: () => setState(() { _customMode = true; _selectedAmount = null; }),
                ),
              ],
            ),

            // Custom amount input
            if (_customMode) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(color: kAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  hintText: '10 – 50,000',
                  hintStyle: TextStyle(color: kMuted.withValues(alpha: 0.5)),
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
            ],

            const SizedBox(height: 16),

            // Message field
            TextField(
              controller: _messageCtrl,
              maxLength: 250,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '"God bless you and your ministry..."',
                hintStyle: TextStyle(color: kMuted.withValues(alpha: 0.5), fontSize: 13),
                counterStyle: const TextStyle(color: kMuted),
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

            const SizedBox(height: 4),

            // Anonymous toggle
            Row(
              children: [
                Switch(
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                  activeColor: kAccent,
                ),
                const SizedBox(width: 8),
                const Text('Donate Anonymously', style: TextStyle(color: kMuted, fontSize: 14)),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],

            const SizedBox(height: 12),

            // Platform fee note
            if (_effectiveAmount != null && _valid) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kPanel2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Creator receives', style: TextStyle(color: kMuted, fontSize: 13)),
                    Text(
                      '₹${(_effectiveAmount! * 0.90).toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Donate button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_valid && !_loading) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  disabledBackgroundColor: kPanel2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        _effectiveAmount != null && _valid
                            ? 'Donate ₹${_effectiveAmount!.toInt()} 🙏'
                            : 'Select an Amount',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Amount chip ----
class _AmountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AmountChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.15) : kPanel,
          border: Border.all(color: selected ? kAccent : kBorder, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? kAccent : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ---- Creator avatar helper ----
class _Avatar extends StatelessWidget {
  final String name;
  final String avatarUrl;
  const _Avatar({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: kPanel2,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))
          : null,
    );
  }
}

// ---- Success Dialog ----
class _DonationSuccessDialog extends StatelessWidget {
  final double amount;
  final String creatorName;
  final String transactionId;
  const _DonationSuccessDialog({
    required this.amount,
    required this.creatorName,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Donation Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'You donated ₹${amount.toInt()} to $creatorName',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              '"For where your treasure is, there your heart will be also." — Matthew 6:21',
              style: TextStyle(color: kMuted, fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (transactionId.isNotEmpty)
              Text('Ref: $transactionId',
                  style: const TextStyle(color: kMuted, fontSize: 11)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('God Bless You 🙏',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
