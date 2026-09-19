import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../core/theme/console_theme.dart';
import '../../core/widgets/console_ui.dart';
import '../terminal/terminal_screen.dart';

class HandshakeScreen extends StatefulWidget {
  const HandshakeScreen({
    required this.nodeId,
    required this.alias,
    required this.fingerprint,
    super.key,
  });

  final String nodeId;
  final String alias;
  final String fingerprint;

  @override
  State<HandshakeScreen> createState() => _HandshakeScreenState();
}

class _HandshakeScreenState extends State<HandshakeScreen> {
  final List<String> _log = [];
  bool _processing = false;

  Future<void> _accept() async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _log.clear();
    });

    for (final line in <String>[
      '> сверка участников',
      '> согласование канала',
      '> регистрация локальной сессии',
      'CHANNEL READY',
    ]) {
      await Future<void>.delayed(const Duration(milliseconds: 360));
      if (!mounted) return;
      setState(() => _log.add(line));
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(
        builder: (_) => TerminalScreen(
          nodeId: widget.nodeId,
          alias: widget.alias,
        ),
      ),
    );
  }

  void _reject() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('ПОДКЛЮЧЕНИЕ ОТКЛОНЕНО'),
        message: const Text('Доступ к терминалу не предоставлен.'),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(this.context);
          },
          child: const Text('ЗАКРЫТЬ'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConsolePage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          ConsoleHeader(
            title: 'HANDSHAKE',
            subtitle: 'console://connection/${widget.nodeId}',
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 18),
          const ConsoleLabel('INCOMING CONNECTION REQUEST', color: ConsoleColors.warning),
          const SizedBox(height: 8),
          const Text(
            'ПОПЫТКА\nПОДКЛЮЧЕНИЯ',
            style: TextStyle(
              color: ConsoleColors.text,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w900,
              fontSize: 29,
              height: 1.03,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 24),
          ConsolePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HandshakeRow(label: 'УЗЕЛ', value: 'NODE://${widget.nodeId}'),
                _HandshakeRow(label: 'ПСЕВДОНИМ', value: widget.alias),
                _HandshakeRow(label: 'СТАТУС ДОВЕРИЯ', value: 'НЕОПРЕДЕЛЁН', warning: true),
                const SizedBox(height: 14),
                const ConsoleLabel('ОТПЕЧАТОК'),
                const SizedBox(height: 8),
                Text(
                  widget.fingerprint,
                  style: const TextStyle(
                    color: ConsoleColors.secondary,
                    fontFamily: 'Courier',
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                if (_log.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(height: 1, color: ConsoleColors.border),
                  const SizedBox(height: 12),
                  ..._log.map(
                    (line) => SystemLine(
                      line,
                      status: line == 'CHANNEL READY'
                          ? SystemLineStatus.success
                          : SystemLineStatus.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          ConsoleButton(
            label: _processing ? 'СОГЛАСОВАНИЕ...' : 'РАЗРЕШИТЬ ДОСТУП',
            onPressed: _processing ? null : _accept,
          ),
          const SizedBox(height: 10),
          ConsoleButton(
            label: 'ОТКЛОНИТЬ',
            filled: false,
            destructive: true,
            onPressed: _processing ? null : _reject,
          ),
          const SizedBox(height: 16),
          const Text(
            'Intro payload в этой версии не показывается до разрешения соединения. Реальная серверная Handshake state machine будет подключена отдельным этапом.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ConsoleColors.tertiary,
              fontFamily: 'Courier',
              fontSize: 9,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandshakeRow extends StatelessWidget {
  const _HandshakeRow({
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: warning ? ConsoleColors.warning : ConsoleColors.text,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
