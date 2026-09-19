import 'package:flutter/cupertino.dart';

import '../theme/console_theme.dart';

class ConsolePage extends StatelessWidget {
  const ConsolePage({
    required this.child,
    this.bottom,
    super.key,
  });

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: ConsoleColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: child),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

class ConsoleHeader extends StatelessWidget {
  const ConsoleHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Row(
        children: [
          if (onBack != null) ...[
            ConsoleIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: onBack!,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ConsoleColors.text,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ConsoleColors.tertiary,
                      fontFamily: 'Courier',
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ConsoleIconButton extends StatelessWidget {
  const ConsoleIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 40,
      onPressed: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ConsoleColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ConsoleColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: ConsoleColors.text, size: 18),
      ),
    );
  }
}

class ConsoleButton extends StatelessWidget {
  const ConsoleButton({
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.filled = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? ConsoleColors.danger : ConsoleColors.accent;
    final foreground = filled ? ConsoleColors.background : accent;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: onPressed == null ? 0.45 : 1,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: filled ? accent : ConsoleColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.55)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class ConsolePanel extends StatelessWidget {
  const ConsolePanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: ConsoleColors.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ConsoleColors.border),
      ),
      child: child,
    );
  }
}

class ConsoleLabel extends StatelessWidget {
  const ConsoleLabel(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color ?? ConsoleColors.tertiary,
        fontFamily: 'Courier',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.15,
      ),
    );
  }
}

class SystemLine extends StatelessWidget {
  const SystemLine(
    this.text, {
    this.status = SystemLineStatus.normal,
    super.key,
  });

  final String text;
  final SystemLineStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SystemLineStatus.success => ConsoleColors.accent,
      SystemLineStatus.warning => ConsoleColors.warning,
      SystemLineStatus.error => ConsoleColors.danger,
      SystemLineStatus.dim => ConsoleColors.tertiary,
      SystemLineStatus.normal => ConsoleColors.secondary,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontFamily: 'Courier',
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }
}

enum SystemLineStatus { normal, success, warning, error, dim }

class ConsoleStatusDot extends StatelessWidget {
  const ConsoleStatusDot({required this.connected, super.key});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: connected ? ConsoleColors.accent : ConsoleColors.tertiary,
        shape: BoxShape.circle,
        boxShadow: connected
            ? [
                BoxShadow(
                  color: ConsoleColors.accent.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
    );
  }
}
