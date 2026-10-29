import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_constants.dart';
import '../../l10n/l10n.dart';
import '../../providers/locale_provider.dart';
import '../../routing/app_routes.dart';
import '../../services/time_zone_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/money.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_states.dart';
import '../../services/auth_repository.dart';
import '../../providers/settings_actions.dart';

/// Settings: profile, password, language, currency, time zone,
/// notifications, privacy, delete account and log out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(authStateProvider).value;
    final profile = ref.watch(currentUserProfileProvider).value;
    final locale = ref.watch(localeProvider);
    final hasPassword = ref.watch(hasPasswordProvider);
    final zone = ref.watch(deviceTimeZoneProvider).value ?? '…';
    final currency = profile?.currency ?? AppConstants.defaultCurrency;
    final name = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName
        : user?.displayName ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Profile card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (name.isNotEmpty ? name : user?.email ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: AppTextStyles.headlineMedium
                        .copyWith(color: Colors.white),
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.titleLarge),
                      const Gap(2),
                      Text(user?.email ?? '',
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),

          // ── Account ────────────────────────────────────────────
          _SectionHeader(l.settingsAccount),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: l.settingsEditProfile,
            subtitle: l.settingsEditProfileDesc,
            onTap: () => context.go(AppRoutes.editProfile),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: l.settingsChangePassword,
            subtitle: hasPassword
                ? l.settingsChangePasswordDesc
                : l.settingsPasswordGoogle,
            onTap: hasPassword ? () => context.go(AppRoutes.changePassword) : null,
          ),
          const Gap(16),

          // ── Preferences ────────────────────────────────────────
          _SectionHeader(l.settingsPreferences),
          _SettingsTile(
            icon: Icons.language_rounded,
            title: l.settingsLanguage,
            subtitle:
                locale.languageCode == 'km' ? l.languageKhmer : l.languageEnglish,
            onTap: () => _chooseLanguage(context, ref),
          ),
          _SettingsTile(
            icon: Icons.currency_exchange_rounded,
            title: l.settingsCurrency,
            subtitle: currency,
            onTap: () => _chooseCurrency(context, ref, currency),
          ),
          _SettingsTile(
            icon: Icons.public_rounded,
            title: l.settingsTimeZone,
            subtitle: l.settingsTimeZoneAuto(zone),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.background,
                title: Text(l.timeZoneTitle),
                content: Text(l.timeZoneBody(zone)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.commonClose),
                  ),
                ],
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: l.settingsNotifications,
            subtitle: l.settingsNotificationsDesc,
            onTap: () => context.go(AppRoutes.notificationSettings),
          ),
          const Gap(16),

          // ── Privacy & data ─────────────────────────────────────
          _SectionHeader(l.settingsPrivacyData),
          _SettingsTile(
            icon: Icons.cloud_done_outlined,
            title: l.settingsExportData,
            subtitle: l.settingsExportDataDesc,
            onTap: () => context.go(AppRoutes.reports),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l.settingsPrivacy,
            subtitle: l.settingsPrivacyDesc,
            onTap: () => context.go(AppRoutes.privacy),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: l.settingsDeleteAccount,
            subtitle: l.settingsDeleteAccountDesc,
            color: AppColors.error,
            onTap: () => context.go(AppRoutes.deleteAccount),
          ),
          const Gap(28),

          AppOutlinedButton(
            label: l.settingsLogOut,
            icon: Icons.logout_rounded,
            onPressed: () => _confirmLogout(context, ref),
          ),
          const Gap(12),
          Center(
            child: Text(l.settingsVersion(AppConstants.appVersion),
                style: AppTextStyles.caption),
          ),
          const Gap(24),
        ],
      ),
    );
  }

  Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final current = ref.read(localeProvider).languageCode;
    final code = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l.chooseLanguage, style: AppTextStyles.titleLarge)),
            for (final (c, label) in [('en', l.languageEnglish), ('km', l.languageKhmer)])
              ListTile(
                title: Text(label),
                trailing: c == current
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
    if (code == null || code == current) return;
    try {
      await ref.read(localeProvider.notifier).setLanguage(code);
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  Future<void> _chooseCurrency(
      BuildContext context, WidgetRef ref, String current) async {
    final l = context.l10n;
    final code = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(l.chooseCurrency, style: AppTextStyles.titleLarge),
              subtitle: Text(l.currencyNote, style: AppTextStyles.bodySmall),
            ),
            for (final c in Currencies.supported)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.softTeal,
                  child: Text(c.symbol.trim(),
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.primary)),
                ),
                title: Text(c.code),
                trailing: c.code == current
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(c.code),
              ),
          ],
        ),
      ),
    );
    if (code == null || code == current) return;
    try {
      await ref.read(settingsActionsProvider).setCurrency(code);
      if (context.mounted) AppSnackBar.success(context, context.l10n.commonSaved);
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l.settingsLogOut,
      message: l.settingsLogOutConfirm,
      confirmLabel: l.settingsLogOut,
      destructive: true,
    );
    if (confirmed) {
      await ref.read(settingsActionsProvider).logOut();
      // GoRouter's auth redirect navigates to the login screen.
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// null = shown but not tappable (e.g. password for Google accounts).
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: AppTextStyles.titleMedium.copyWith(
              color: color == AppColors.error ? AppColors.error : null)),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
