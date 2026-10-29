import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_card.dart';

/// Plain-language privacy information (English and Khmer).
///
/// ⚠️  Before publishing to the stores you also need a public privacy
/// policy URL (required by Google Play and the App Store). This screen
/// explains how the app works; it is not a legal document.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sections = [
      (Icons.inventory_2_outlined, l.privacyWhatTitle, l.privacyWhatBody),
      (Icons.cloud_outlined, l.privacyWhereTitle, l.privacyWhereBody),
      (Icons.shield_outlined, l.privacyWhoTitle, l.privacyWhoBody),
      (Icons.notifications_outlined, l.privacyDeviceTitle, l.privacyDeviceBody),
      (Icons.ios_share_rounded, l.privacyExportTitle, l.privacyExportBody),
      (Icons.delete_outline_rounded, l.privacyDeleteTitle, l.privacyDeleteBody),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.privacyTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const Gap(12),
        itemBuilder: (context, i) {
          final (icon, title, body) = sections[i];
          return AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primary),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      const Gap(4),
                      Text(body,
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
