import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../core/theme/console_theme.dart';
import '../../core/widgets/console_ui.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({
    required this.nodeId,
    required this.alias,
    super.key,
  });

  final String nodeId;
  final String alias;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random.secure();
  final List<_TerminalMessage> _messages = [
    _TerminalMessage(
      id: 'seed-1',
      text: 'канал открыт. ты здесь?',
      mine: false,
      status: _MessageStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    _TerminalMessage(
      id: 'seed-2',
      text: 'да. связь чистая.',
      mine: true,
      status: _MessageStatus.read,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final id = '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(99999)}';
    _controller.clear();
    setState(() {
      _messages.add(
        _TerminalMessage(
          id: id,
          text: text,
          mine: true,
          status: _MessageStatus.sending,
          createdAt: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    Timer(const Duration(milliseconds: 170), () {
      if (!mounted) return;
      _setStatus(id, _MessageStatus.sent);
    });
    Timer(const Duration(milliseconds: 430), () {
      if (!mounted) return;
      _setStatus(id, _MessageStatus.delivered);
    });
  }

  void _setStatus(String id, _MessageStatus status) {
    final index = _messages.indexWhere((message) => message.id == id);
    if (index < 0) return;
    setState(() => _messages[index] = _messages[index].copyWith(status: status));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _burnTerminal() async {
    final accepted = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('НЕОБРАТИМАЯ ОПЕРАЦИЯ'),
        message: const Text(
          'Локальная история этого прототипа будет удалена из текущей сессии. Это не удаляет копии на других устройствах или сервере.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('СЖЕЧЬ ТЕРМИНАЛ'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ОТМЕНА'),
        ),
      ),
    );

    if (accepted != true || !mounted) return;
    setState(() => _messages.clear());
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('ТЕРМИНАЛ УНИЧТОЖЕН'),
        content: const Text('Локальная история текущей сессии очищена.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context);
            },
            child: const Text('ЗАКРЫТЬ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConsolePage(
      child: Column(
        children: [
          ConsoleHeader(
            title: 'console://terminal/${widget.nodeId}',
            subtitle: '${widget.alias} • CONNECTED',
            onBack: () => Navigator.pop(context),
            trailing: ConsoleIconButton(
              icon: CupertinoIcons.ellipsis,
              onPressed: _burnTerminal,
            ),
          ),
          Container(height: 1, color: ConsoleColors.border),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: Row(
              children: [
                ConsoleStatusDot(connected: true),
                SizedBox(width: 8),
                Text(
                  'СЕССИЯ АКТИВНА',
                  style: TextStyle(
                    color: ConsoleColors.accent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.9,
                  ),
                ),
                Spacer(),
                Text(
                  'LOCAL PROTOTYPE',
                  style: TextStyle(
                    color: ConsoleColors.tertiary,
                    fontFamily: 'Courier',
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'РЕЗУЛЬТАТОВ: 0',
                      style: TextStyle(
                        color: ConsoleColors.tertiary,
                        fontFamily: 'Courier',
                        fontSize: 11,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          _Composer(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _TerminalMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF102114) : ConsoleColors.panel,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: mine ? ConsoleColors.accentMuted : ConsoleColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: ConsoleColors.text,
                fontFamily: 'Courier',
                fontSize: 13,
                height: 1.38,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              mine ? _statusText(message.status) : 'ВХОДЯЩИЕ ДАННЫЕ',
              style: TextStyle(
                color: message.status == _MessageStatus.delivered ||
                        message.status == _MessageStatus.read
                    ? ConsoleColors.accent
                    : ConsoleColors.tertiary,
                fontFamily: 'Courier',
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusText(_MessageStatus status) {
    return switch (status) {
      _MessageStatus.sending => 'ПЕРЕДАЧА',
      _MessageStatus.sent => 'КОМАНДА ОТПРАВЛЕНА',
      _MessageStatus.delivered => 'ДАННЫЕ ДОСТАВЛЕНЫ',
      _MessageStatus.read => 'ВЫВОД ПОДТВЕРЖДЁН',
    };
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ConsoleColors.panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ConsoleColors.border),
              ),
              child: CupertinoTextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                placeholder: 'user@console:~$ ввод',
                placeholderStyle: const TextStyle(
                  color: ConsoleColors.tertiary,
                  fontFamily: 'Courier',
                  fontSize: 11,
                ),
                style: const TextStyle(
                  color: ConsoleColors.text,
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: null,
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: ConsoleColors.accent,
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.arrow_up,
                color: ConsoleColors.background,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MessageStatus { sending, sent, delivered, read }

class _TerminalMessage {
  const _TerminalMessage({
    required this.id,
    required this.text,
    required this.mine,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool mine;
  final _MessageStatus status;
  final DateTime createdAt;

  _TerminalMessage copyWith({_MessageStatus? status}) {
    return _TerminalMessage(
      id: id,
      text: text,
      mine: mine,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
