import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// Plant contact + a few FAQs for the customer.
const String kPlantPhone = '91XXXXXXXXXX';
const String kPlantName = 'Mahalakshmi Water Plant';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I place a bulk order?',
      'Tap "Request Bulk Order" on the home screen, fill in your event details, '
          'and pay the 30% advance to confirm.',
    ),
    (
      'Why do I pay 30% advance?',
      'The 30% advance confirms your booking and blocks your event date. The '
          'remaining 70% is paid as cash on delivery.',
    ),
    (
      'Is the advance refundable?',
      'No — the 30% advance is non-refundable. If you cancel, the date is not '
          'unblocked.',
    ),
    (
      'When is a delivery charge added?',
      'A delivery charge applies only to orders under 25 cans, for every '
          'village except Kasara Balkunda (which is free).',
    ),
    (
      'How will I know my booking is confirmed?',
      'Online payments confirm instantly. For cash, the plant confirms once the '
          'advance is received — you can track it under "My Bookings".',
    ),
  ];

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: '+$kPlantPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final uri = Uri.parse('https://wa.me/$kPlantPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brand),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Help & Support',
            style: TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
                fontSize: 19)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          // contact card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.blueGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need help with an order?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Reach out to $kPlantName directly.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ContactBtn(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        onTap: _call,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ContactBtn(
                        icon: Icons.chat_rounded,
                        label: 'WhatsApp',
                        onTap: _whatsapp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Frequently asked',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          for (final f in _faqs) _FaqItem(question: f.$1, answer: f.$2),
          const SizedBox(height: 20),
          Center(
            child: Text('$kPlantName · ThakaThok',
                style: const TextStyle(fontSize: 11.5, color: AppColors.hint)),
          ),
        ],
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  const _ContactBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.brand),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          iconColor: AppColors.brand,
          collapsedIconColor: AppColors.brand,
          title: Text(question,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(answer,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.body, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
