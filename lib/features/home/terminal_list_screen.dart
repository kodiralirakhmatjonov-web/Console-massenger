import 'package:flutter/cupertino.dart';

import '../../core/security/identity_service.dart';
import '../../core/theme/console_theme.dart';
import '../../core/widgets/console_ui.dart';
import '../discover/node_discovery_screen.dart';
import '../identity/identity_screen.dart';
import '../terminal/terminal_screen.dart';

class TerminalListScreen extends StatefulWidget {
  const TerminalListScreen({
    required this.identity,
    required this.identityService,
    required this.onIdentityDestroyed,
    super.key,
  });

  final ConsoleIdentity identity;
  final IdentityService identityService;
  final VoidCallback onIdentityDestroyed;

  @override
  State<TerminalListScreen> createState() => _TerminalListScreenState();
}

class _TerminalListScreenState extends State<TerminalListScreen> {
  int _tab = 0;

  void _openTerminal(String nodeId, String alias) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => TerminalScreen(nodeId: nodeId, alias: alias),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _TerminalsView(
        identity: widget.identity,
        onOpenTerminal: _openTerminal,
        onDiscover: () => setState(() => _tab = 1),
      ),
      NodeDiscoveryScreen(
        embedded: true,
        identity: widget.identity,
      ),
      IdentityScreen(
        embedded: true,
        identity: widget.identity,
        identityService: widget.identityService,
        onIdentityDestroyed: widget.onIdentityDestroyed,
      ),
    ];

    return ConsolePage(
      child: IndexedStack(index: _tab, children: pages),
      bottom: _BottomBar(
        index: _tab,
        onChanged: (index) => setState(() => _tab = index),
      ),
    );
  }
}

class _TerminalsView extends StatelessWidget {
  const _TerminalsView({
    required this.identity,
    required this.onOpenTerminal,
    required this.onDiscover,
  });

  final ConsoleIdentity identity;
  final void Function(String nodeId, String alias) onOpenTerminal;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: ConsoleColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ConsoleColors.accent.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'CONSOLE',
                        style: TextStyle(
                          color: ConsoleColors.text,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: ConsoleColors.panel,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ConsoleColors.border),
                      ),
                      child: Text(
                        'NODE://${identity.nodeId}',
                        style: const TextStyle(
                          color: ConsoleColors.accent,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                const ConsoleLabel('ACTIVE NETWORK'),
                const SizedBox(height: 7),
                const Text(
                  'ТЕРМИНАЛЫ',
                  style: TextStyle(
                    color: ConsoleColors.text,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Сессии, которым вы предоставили доступ.',
                  style: TextStyle(
                    color: ConsoleColors.secondary,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onDiscover,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: ConsoleColors.panel,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: ConsoleColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.search, color: ConsoleColors.accent, size: 18),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'НАЙТИ УЗЕЛ / УСТАНОВИТЬ СОЕДИНЕНИЕ',
                            style: TextStyle(
                              color: ConsoleColors.secondary,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Icon(CupertinoIcons.chevron_right, color: ConsoleColors.tertiary, size: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _TerminalTile(
                  alias: 'UserX',
                  nodeId: '7X91',
                  preview: 'связь на месте. увидимся позже',
                  connected: true,
                  unread: 2,
                  onTap: () => onOpenTerminal('7X91', 'UserX'),
                ),
                const SizedBox(height: 10),
                _TerminalTile(
                  alias: 'Mira',
                  nodeId: 'A4C8',
                  preview: '> файл принят',
                  connected: false,
                  unread: 0,
                  onTap: () => onOpenTerminal('A4C8', 'Mira'),
                ),
                const SizedBox(height: 10),
                _TerminalTile(
                  alias: 'dev_null',
                  nodeId: '19F0',
                  preview: 'deploy прошёл',
                  connected: true,
                  unread: 0,
                  onTap: () => onOpenTerminal('19F0', 'dev_null'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'PROTOCOL BUILD 0.1 • LOCAL CHAT UI\nNETWORK TRANSPORT PREPARED, NOT YET CONNECTED',
                  style: TextStyle(
                    color: ConsoleColors.tertiary,
                    fontFamily: 'Courier',
                    fontSize: 9,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TerminalTile extends StatelessWidget {
  const _TerminalTile({
    required this.alias,
    required this.nodeId,
    required this.preview,
    required this.connected,
    required this.unread,
    required this.onTap,
  });

  final String alias;
  final String nodeId;
  final String preview;
  final bool connected;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ConsolePanel(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ConsoleColors.panelRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ConsoleColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                nodeId.substring(0, 2),
                style: const TextStyle(
                  color: ConsoleColors.accent,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          alias,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ConsoleColors.text,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      ConsoleStatusDot(connected: connected),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ConsoleColors.secondary,
                      fontFamily: 'Courier',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: ConsoleColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: ConsoleColors.background,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ConsoleColors.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ConsoleColors.border),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: CupertinoIcons.rectangle_stack,
            label: 'TERMINALS',
            active: index == 0,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            icon: CupertinoIcons.scope,
            label: 'DISCOVER',
            active: index == 1,
            onTap: () => onChanged(1),
          ),
          _NavItem(
            icon: CupertinoIcons.person_crop_circle,
            label: 'IDENTITY',
            active: index == 2,
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            color: active ? ConsoleColors.panelRaised : const Color(0x00000000),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? ConsoleColors.accent : ConsoleColors.tertiary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? ConsoleColors.text : ConsoleColors.tertiary,
                  fontFamily: 'Courier',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
