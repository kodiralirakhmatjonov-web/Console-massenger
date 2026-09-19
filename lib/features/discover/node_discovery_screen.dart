import 'package:flutter/cupertino.dart';

import '../../core/security/identity_service.dart';
import '../../core/theme/console_theme.dart';
import '../../core/widgets/console_ui.dart';
import '../handshake/handshake_screen.dart';

class NodeDiscoveryScreen extends StatefulWidget {
  const NodeDiscoveryScreen({
    required this.identity,
    this.embedded = false,
    super.key,
  });

  final ConsoleIdentity identity;
  final bool embedded;

  @override
  State<NodeDiscoveryScreen> createState() => _NodeDiscoveryScreenState();
}

class _NodeDiscoveryScreenState extends State<NodeDiscoveryScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scan() {
    FocusScope.of(context).unfocus();
    setState(() => _scanned = true);
  }

  void _openHandshake() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => const HandshakeScreen(
          nodeId: '7X91',
          alias: 'unknown_7X91',
          fingerprint: '94:A7:21:CF:83:10:8B:2D:11:7E:A0:5C',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
      children: [
        const ConsoleLabel('NETWORK DISCOVERY'),
        const SizedBox(height: 8),
        const Text(
          'НАЙТИ УЗЕЛ',
          style: TextStyle(
            color: ConsoleColors.text,
            fontFamily: 'Courier',
            fontWeight: FontWeight.w900,
            fontSize: 30,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Введите Node ID или публичную сигнатуру. В этой сборке discovery использует локальный прототип результата.',
          style: TextStyle(
            color: ConsoleColors.secondary,
            fontFamily: 'Courier',
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: ConsoleColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ConsoleColors.border),
          ),
          child: CupertinoTextField(
            controller: _controller,
            placeholder: 'NODE ID / SIGNATURE',
            placeholderStyle: const TextStyle(
              color: ConsoleColors.tertiary,
              fontFamily: 'Courier',
              fontSize: 12,
            ),
            style: const TextStyle(
              color: ConsoleColors.text,
              fontFamily: 'Courier',
              fontSize: 13,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            decoration: null,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _scan(),
          ),
        ),
        const SizedBox(height: 12),
        ConsoleButton(label: 'СКАНИРОВАТЬ СЕТЬ', onPressed: _scan),
        if (_scanned) ...[
          const SizedBox(height: 24),
          const SystemLine('> сканирование сети'),
          const SystemLine('> проверка публичной сигнатуры'),
          const SystemLine('СОВПАДЕНИЙ: 1', status: SystemLineStatus.success),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _openHandshake,
            child: ConsolePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      ConsoleStatusDot(connected: true),
                      SizedBox(width: 9),
                      Text(
                        'NODE://7X91',
                        style: TextStyle(
                          color: ConsoleColors.text,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        CupertinoIcons.chevron_right,
                        color: ConsoleColors.tertiary,
                        size: 15,
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  const ConsoleLabel('ОТПЕЧАТОК'),
                  const SizedBox(height: 6),
                  const Text(
                    '94:A7:21:CF:83:10:8B:2D:11:7E:A0:5C',
                    style: TextStyle(
                      color: ConsoleColors.secondary,
                      fontFamily: 'Courier',
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: ConsoleColors.border),
                  const SizedBox(height: 12),
                  const Text(
                    'УСТАНОВИТЬ СОЕДИНЕНИЕ',
                    style: TextStyle(
                      color: ConsoleColors.accent,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    if (widget.embedded) return body;
    return ConsolePage(child: body);
  }
}
