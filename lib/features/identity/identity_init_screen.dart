import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../core/security/identity_service.dart';
import '../../core/theme/console_theme.dart';
import '../../core/widgets/console_ui.dart';

class IdentityInitScreen extends StatefulWidget {
  const IdentityInitScreen({
    required this.identityService,
    required this.onInitialized,
    super.key,
  });

  final IdentityService identityService;
  final ValueChanged<ConsoleIdentity> onInitialized;

  @override
  State<IdentityInitScreen> createState() => _IdentityInitScreenState();
}

class _IdentityInitScreenState extends State<IdentityInitScreen> {
  final List<_LogEntry> _logs = [];
  bool _running = false;
  ConsoleIdentity? _created;

  Future<void> _initialize() async {
    if (_running) return;
    setState(() {
      _running = true;
      _logs.clear();
      _created = null;
    });

    await _append('> сбор системной энтропии');
    await _append('> создание локальной пары Ed25519');

    try {
      final identity = await widget.identityService.createIdentity();
      if (!mounted) return;
      await _append('> сохранение закрытого ключа в защищённом хранилище');
      await _append('> вычисление публичной сигнатуры');
      await _append('IDENTITY INITIALIZED', success: true, delay: 450);
      if (!mounted) return;
      setState(() {
        _created = identity;
        _running = false;
      });
    } catch (_) {
      await _append('ОПЕРАЦИЯ ОТКЛОНЕНА', error: true, delay: 0);
      if (!mounted) return;
      setState(() => _running = false);
    }
  }

  Future<void> _append(
    String value, {
    bool success = false,
    bool error = false,
    int delay = 330,
  }) async {
    if (delay > 0) {
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
    if (!mounted) return;
    setState(() => _logs.add(_LogEntry(value, success: success, error: error)));
  }

  @override
  Widget build(BuildContext context) {
    return ConsolePage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 34, 22, 28),
        children: [
          const Text(
            '> CONSOLE',
            style: TextStyle(
              color: ConsoleColors.accent,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'ИНИЦИАЛИЗАЦИЯ',
            style: TextStyle(
              color: ConsoleColors.text,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w800,
              fontSize: 31,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Создайте свою Identity. Закрытый ключ формируется на этом устройстве и не отправляется на сервер.',
            style: TextStyle(
              color: ConsoleColors.secondary,
              fontFamily: 'Courier',
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          ConsolePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ConsoleLabel('IDENTITY PROTOCOL / V0.1'),
                const SizedBox(height: 16),
                const _ProtocolRow(
                  label: 'АЛГОРИТМ',
                  value: 'Ed25519',
                ),
                const _ProtocolRow(
                  label: 'PRIVATE KEY',
                  value: 'LOCAL ONLY',
                  valueColor: ConsoleColors.accent,
                ),
                const _ProtocolRow(
                  label: 'RECOVERY',
                  value: 'НЕ НАСТРОЕНО',
                  valueColor: ConsoleColors.warning,
                ),
                if (_logs.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(height: 1, color: ConsoleColors.border),
                  const SizedBox(height: 14),
                  ..._logs.map(
                    (entry) => SystemLine(
                      entry.text,
                      status: entry.error
                          ? SystemLineStatus.error
                          : entry.success
                              ? SystemLineStatus.success
                              : SystemLineStatus.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_created != null) ...[
            const SizedBox(height: 14),
            ConsolePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ConsoleLabel('ВАША СИГНАТУРА'),
                  const SizedBox(height: 12),
                  Text(
                    'NODE://${_created!.nodeId}',
                    style: const TextStyle(
                      color: ConsoleColors.accent,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _created!.fingerprint,
                    style: const TextStyle(
                      color: ConsoleColors.secondary,
                      fontFamily: 'Courier',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_created == null)
            ConsoleButton(
              label: _running ? 'ИНИЦИАЛИЗАЦИЯ...' : 'ИНИЦИАЛИЗИРОВАТЬ ЛИЧНОСТЬ',
              onPressed: _running ? null : _initialize,
            )
          else
            ConsoleButton(
              label: 'ВОЙТИ В СЕТЬ',
              onPressed: () => widget.onInitialized(_created!),
            ),
          const SizedBox(height: 18),
          const Text(
            'Recovery phrase намеренно отсутствует в этой версии: схема восстановления будет добавлена только после отдельной спецификации и threat model.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ConsoleColors.tertiary,
              fontFamily: 'Courier',
              fontSize: 10,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  const _ProtocolRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ConsoleColors.tertiary,
                fontFamily: 'Courier',
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? ConsoleColors.text,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  const _LogEntry(this.text, {this.success = false, this.error = false});

  final String text;
  final bool success;
  final bool error;
}
