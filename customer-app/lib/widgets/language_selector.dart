import 'package:flutter/material.dart';

import '../services/language_service.dart';
import '../theme/app_colors.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key, this.compact = false});

  final bool compact;

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  @override
  void initState() {
    super.initState();
    LanguageService.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = LanguageService.instance;
    return PopupMenuButton<AppLanguage>(
      tooltip: tr('Language'),
      initialValue: service.language,
      onSelected: service.setLanguage,
      itemBuilder: (_) => [
        PopupMenuItem(value: AppLanguage.english, child: Text(tr('English'))),
        PopupMenuItem(value: AppLanguage.hindi, child: Text(tr('Hindi'))),
        PopupMenuItem(value: AppLanguage.marathi, child: Text(tr('Marathi'))),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 9 : 12,
          vertical: widget.compact ? 7 : 9,
        ),
        decoration: BoxDecoration(
          color: AppColors.tint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.liveBrand.withValues(alpha: .15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded,
                size: widget.compact ? 18 : 20, color: AppColors.liveBrand),
            const SizedBox(width: 6),
            Text(
              service.languageName,
              style: TextStyle(
                color: AppColors.liveBrand,
                fontWeight: FontWeight.w600,
                fontSize: widget.compact ? 11 : 12,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 17, color: AppColors.liveBrand),
          ],
        ),
      ),
    );
  }
}
