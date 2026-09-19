import 'package:flutter/cupertino.dart';

import '../../core/security/identity_service.dart';
import '../../core/theme/console_theme.dart';
import '../../core/widgets/console_ui.dart';

class IdentityScreen extends StatelessWidget {
  const IdentityScreen({
    required this.identity,
    required this.identityService,
    required this.onIdentityDestroyed,
    this.embedded = false,
    super.key,
  });

  final ConsoleIdentity identity;
  final IdentityService identityService;
  final VoidCallback onIdentityDestroyed;
  final bool embedded;

  Future<void> _confirmDestroy(BuildContext context) async {
    final accepted = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('УНИЧТОЖИТЬ ЛОКАЛЬНУЮ IDENTITY?'),
        message: const Text(
          'Будут удалены локально сохранённые ключи этой тестовой Identity. Восстановление в текущей версии отсутствует.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('УНИЧТОЖИТЬ'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ОТМЕНА'),
        ),
      ),
    );

    if (accepted != true) return;
    await identityService.destroyLocalIdentity();
    onIdentityDestroyed();
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
      children: [
        const ConsoleLabel('LOCAL CRYPTOGRAPHIC IDENTITY'),
        const SizedBox(height: 8),
        const Text(
          'СИГНАТУРА',
          style: TextStyle(
            color: ConsoleColors.text,
            fontFamily: 'Courier',
            fontWeight: FontWeight.w900,
            fontSize: 30,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 22),
        ConsolePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConsoleLabel('NODE'),
              const SizedBox(height: 9),
              Text(
                'NODE://${identity.nodeId}',
                style: const TextStyle(
                  color: ConsoleColors.accent,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 24),
              const ConsoleLabel('ОТПЕЧАТОК'),
              const SizedBox(height: 9),
              SelectableText(
                identity.fingerprint,
                style: const TextStyle(
                  color: ConsoleColors.text,
                  fontFamily: 'Courier',
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              const _InfoRow(label: 'АЛГОРИТМ', value: 'Ed25519'),
              const _InfoRow(
                label: 'PRIVATE KEY',
                value: 'LOCAL STORAGE',
                color: ConsoleColors.accent,
              ),
              const _InfoRow(
                label: 'RECOVERY',
                value: 'НЕ НАСТРОЕНО',
                color: ConsoleColors.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ConsolePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConsoleLabel('PUBLIC KEY'),
              const SizedBox(height: 10),
              SelectableText(
                identity.publicKeyBase64,
                style: const TextStyle(
                  color: ConsoleColors.secondary,
                  fontFamily: 'Courier',
                  fontSize: 10,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ConsoleButton(
          label: 'УНИЧТОЖИТЬ ЛОКАЛЬНУЮ IDENTITY',
          destructive: true,
          filled: false,
          onPressed: () => _confirmDestroy(context),
        ),
        const SizedBox(height: 14),
        const Text(
          'Это не удаляет данные с других устройств или серверные записи. Формулировка ограничена тем, что приложение действительно может гарантировать.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ConsoleColors.tertiary,
            fontFamily: 'Courier',
            fontSize: 9,
            height: 1.45,
          ),
        ),
      ],
    );

    if (embedded) return body;
    return ConsolePage(child: body);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ConsoleColors.tertiary,
                fontFamily: 'Courier',
                fontSize: 10,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? ConsoleColors.text,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
