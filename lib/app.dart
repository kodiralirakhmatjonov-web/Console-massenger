import 'package:flutter/cupertino.dart';

import 'core/security/identity_service.dart';
import 'core/theme/console_theme.dart';
import 'features/home/terminal_list_screen.dart';
import 'features/identity/identity_init_screen.dart';

class ConsoleApp extends StatefulWidget {
  const ConsoleApp({super.key});

  @override
  State<ConsoleApp> createState() => _ConsoleAppState();
}

class _ConsoleAppState extends State<ConsoleApp> {
  final IdentityService _identityService = IdentityService();
  ConsoleIdentity? _identity;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restoreIdentity();
  }

  Future<void> _restoreIdentity() async {
    final identity = await _identityService.loadIdentity();
    if (!mounted) return;
    setState(() {
      _identity = identity;
      _loading = false;
    });
  }

  void _onIdentityCreated(ConsoleIdentity identity) {
    setState(() => _identity = identity);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Console',
      theme: ConsoleTheme.data,
      home: _loading
          ? const _BootScreen()
          : _identity == null
              ? IdentityInitScreen(
                  identityService: _identityService,
                  onInitialized: _onIdentityCreated,
                )
              : TerminalListScreen(
                  identity: _identity!,
                  identityService: _identityService,
                  onIdentityDestroyed: () {
                    setState(() => _identity = null);
                  },
                ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      backgroundColor: ConsoleColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '> CONSOLE',
              style: TextStyle(
                color: ConsoleColors.text,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'INITIALIZING LOCAL SYSTEM',
              style: TextStyle(
                color: ConsoleColors.tertiary,
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
