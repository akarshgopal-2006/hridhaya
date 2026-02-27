import 'package:flutter/material.dart';

import '../app.dart';
import '../services/app_settings.dart';

class SettingsPrivacyScreen extends StatelessWidget {
  const SettingsPrivacyScreen({super.key});

  Future<void> _editMedicalInfo(BuildContext context, AppSettings s) async {
    final abhaCtrl = TextEditingController(text: s.abhaId);
    final bloodCtrl = TextEditingController(text: s.bloodGroup);
    final controller = AppScope.of(context);

    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final padding = MediaQuery.of(context).viewInsets;
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, 18 + padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'First Responder Info',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: abhaCtrl,
                decoration: const InputDecoration(
                  labelText: 'ABHA ID',
                  hintText: 'XX-XXXX-XXXX-XXXX',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bloodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  hintText: 'O+',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      await controller.updateSettings(
        s.copyWith(abhaId: abhaCtrl.text.trim(), bloodGroup: bloodCtrl.text.trim()),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final controller = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete My Health Data'),
        content: const Text(
          'This will erase stored health identifiers on this device (ABHA ID and Blood Group).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await controller.eraseHealthData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health data erased on this device.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return ValueListenableBuilder(
      valueListenable: controller.settings,
      builder: (context, s, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings & Privacy')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                Text(
                  'Permissions',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.backgroundMonitoring,
                  title: const Text('Background Monitoring'),
                  subtitle:
                      const Text('Allow Hridhaya to monitor in the background.'),
                  onChanged: (v) => controller.updateSettings(
                    s.copyWith(backgroundMonitoring: v),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.fallDetection,
                  title: const Text('Fall Detection'),
                  subtitle: const Text('Auto-trigger Safety Loop when a “thud” is detected.'),
                  onChanged: (v) => controller.updateSettings(
                    s.copyWith(fallDetection: v),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'First Responder Info',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_rounded),
                  title: const Text('ABHA ID'),
                  subtitle: Text(s.abhaId),
                  trailing: const Icon(Icons.edit_rounded),
                  onTap: () => _editMedicalInfo(context, s),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bloodtype_rounded),
                  title: const Text('Blood Group'),
                  subtitle: Text(s.bloodGroup),
                  trailing: const Icon(Icons.edit_rounded),
                  onTap: () => _editMedicalInfo(context, s),
                ),
                const SizedBox(height: 18),
                Text(
                  'Privacy (DPDP Act)',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'We keep health identifiers minimal and provide an in-app data erasure control.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('Delete My Health Data'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

