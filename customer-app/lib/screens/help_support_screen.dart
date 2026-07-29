import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/home_content_service.dart';
import '../services/plant_config.dart';
import '../services/app_config_service.dart';
import '../theme/app_colors.dart';

String get kPlantPhone => PlantConfig.instance.plantPhone;
String get kPlantName => PlantConfig.instance.plantName;

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  void initState() {
    super.initState();
    HomeContentService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: '+${intlPhone(kPlantPhone)}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final uri = Uri.parse('https://wa.me/${intlPhone(kPlantPhone)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = HomeContentService.instance.support;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.liveBrand),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          AppConfigService.instance.label('screen_support'),
          style: TextStyle(
            color: AppColors.liveBrand,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.liveBlueGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.heading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content.description.replaceAll('{plant_name}', kPlantName),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
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
          Text(
            content.sectionTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          for (final faq in content.faqs)
            _FaqItem(question: faq.question, answer: faq.answer),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '$kPlantName · ThakaThok',
              style: const TextStyle(fontSize: 11.5, color: AppColors.hint),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  const _ContactBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.liveBrand),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.liveBrand,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
          tilePadding: EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 12),
          iconColor: AppColors.liveBrand,
          collapsedIconColor: AppColors.liveBrand,
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.body,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
