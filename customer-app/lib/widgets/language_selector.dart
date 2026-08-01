import 'package:flutter/material.dart';

import '../services/language_service.dart';
import '../theme/app_colors.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final service = LanguageService.instance;
    return PopupMenuButton<AppLanguage>(
      tooltip: tr('Language'),
      initialValue: service.language,
      onSelected: service.setLanguage,
      itemBuilder: (_) => const [
        PopupMenuItem(value: AppLanguage.english, child: Text('English')),
        PopupMenuItem(value: AppLanguage.hindi, child: Text('हिन्दी')),
        PopupMenuItem(value: AppLanguage.marathi, child: Text('मराठी')),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 12,
          vertical: compact ? 7 : 9,
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
                size: compact ? 18 : 20, color: AppColors.liveBrand),
            const SizedBox(width: 6),
            Text(
              service.languageName,
              style: TextStyle(
                color: AppColors.liveBrand,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 12,
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
