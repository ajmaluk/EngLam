import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_settings.dart';
import 'app_theme.dart';
import 'englam_logo.dart';

const _systemKeyboardChannel = MethodChannel('englam/system_keyboard');
const _handwritingChannel = MethodChannel('englam/handwriting');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(EngLamApp(settings: settings));
}

class EngLamApp extends StatelessWidget {
  const EngLamApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final mode = switch (settings.themeMode) {
          AppThemeMode.dark => ThemeMode.dark,
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.system => ThemeMode.system,
        };
        return MaterialApp(
          title: 'EngLam',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: RootPage(settings: settings),
        );
      },
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _tab = 0;

  Future<void> _openImeSettings() async {
    try {
      await _systemKeyboardChannel.invokeMethod<void>('openImeSettings');
    } catch (_) {}
  }

  Future<void> _showImePicker() async {
    try {
      await _systemKeyboardChannel.invokeMethod<void>('showImePicker');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = [
      LayoutsPage(settings: widget.settings),
      ThemesPage(settings: widget.settings),
      SettingsPage(settings: widget.settings),
    ];

    final titles = ['EngLam', 'Themes', 'Settings'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: EngLamLogo(size: 34),
        ),
        actions: _tab == 0
            ? [
                IconButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          title: const Text('Help'),
                          content: const Text(
                            'Enable EngLam in system keyboard settings, then select it as your current keyboard.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.help_outline, size: 22),
                  tooltip: 'Help',
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      builder: (context) {
                        return SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.keyboard),
                                  title: const Text('Activate Keyboard'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _openImeSettings();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.keyboard_alt_outlined,
                                  ),
                                  title: const Text('Select Keyboard'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _showImePicker();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.more_vert, size: 22),
                  tooltip: 'More',
                ),
              ]
            : null,
      ),
      body: pages[_tab],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              _BottomTab(
                icon: Icons.keyboard_alt_outlined,
                label: 'Layouts',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 10),
              _BottomTab(
                icon: Icons.palette_outlined,
                label: 'Themes',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              const SizedBox(width: 10),
              _BottomTab(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.secondaryContainer : Colors.transparent;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: fg),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LayoutsPage extends StatelessWidget {
  const LayoutsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Layouts',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: settings,
              builder: (context, _) {
                final selectedEnglish =
                    settings.layoutMode == KeyboardLayoutMode.translit &&
                    !settings.isMalayalamMode;
                final selectedAbcMalayalam =
                    settings.layoutMode == KeyboardLayoutMode.translit &&
                    settings.isMalayalamMode;
                final selectedAksharangal =
                    settings.layoutMode == KeyboardLayoutMode.malayalam;
                final selectedHandwriting =
                    settings.layoutMode == KeyboardLayoutMode.handwriting;

                return Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.92,
                      children: [
                        _LayoutPickerTile(
                          label: 'abc → മലയാളം',
                          preview: const _PreviewQwerty(
                            chips: ['ഞാൻ', 'Njan', 'ഞ'],
                            active: 'ഞാൻ',
                          ),
                          selected: selectedAbcMalayalam,
                          onTap: () {
                            settings.setLayoutMode(KeyboardLayoutMode.translit);
                            settings.setMalayalamMode(true);
                          },
                        ),
                        _LayoutPickerTile(
                          label: 'English',
                          preview: const _PreviewQwerty(
                            chips: ['Beau', 'Beautiful', 'Beauty'],
                            active: 'Beautiful',
                          ),
                          selected: selectedEnglish,
                          onTap: () {
                            settings.setLayoutMode(KeyboardLayoutMode.translit);
                            settings.setMalayalamMode(false);
                          },
                        ),
                        _LayoutPickerTile(
                          label: 'കൈയ്യക്ഷാരം',
                          preview: const _PreviewHandwriting(),
                          selected: selectedHandwriting,
                          onTap: () {
                            settings.setLayoutMode(
                              KeyboardLayoutMode.handwriting,
                            );
                            settings.setMalayalamMode(true);
                          },
                        ),
                        _LayoutPickerTile(
                          label: 'അക്ഷരങ്ങൾ',
                          preview: const _PreviewMalayalamGrid(),
                          selected: selectedAksharangal,
                          onTap: () {
                            settings.setLayoutMode(
                              KeyboardLayoutMode.malayalam,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _LayoutPickerWideTile(
                      label: 'Voice typing',
                      preview: const _PreviewVoiceTyping(),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => KeyboardPage(settings: settings),
                    ),
                  );
                },
                child: const Text('Try in app'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutPickerTile extends StatelessWidget {
  const _LayoutPickerTile({
    required this.label,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget preview;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = scheme.surface;
    final fg = scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: preview,
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: ClipPath(
                          clipper: _CornerClipper(),
                          child: Container(
                            width: 64,
                            height: 64,
                            color: scheme.primary,
                            child: const Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 10, bottom: 10),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
              ),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? scheme.onPrimary : fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LayoutPickerWideTile extends StatelessWidget {
  const _LayoutPickerWideTile({
    required this.label,
    required this.preview,
    required this.onTap,
  });

  final String label;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 120, child: preview),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewQwerty extends StatelessWidget {
  const _PreviewQwerty({required this.chips, required this.active});

  final List<String> chips;
  final String active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviewSuggestionRow(chips: chips, active: active),
        const SizedBox(height: 10),
        const Expanded(
          child: _MiniKeyboard(
            keys: [
              ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
              ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
              ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewMalayalamGrid extends StatelessWidget {
  const _PreviewMalayalamGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PreviewSuggestionRow(
          chips: ['ക', 'ഖ', 'ഗ', 'ഘ', 'ങ'],
          active: 'ഗ',
        ),
        const SizedBox(height: 10),
        const Expanded(
          child: _MiniKeyboard(
            keys: [
              ['ക', 'ഖ', 'ഗ', 'ഘ', 'ങ'],
              ['ച', 'ഛ', 'ജ', 'ഝ', 'ഞ'],
              ['ട', 'ഠ', 'ഡ', 'ഢ', 'ണ'],
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewHandwriting extends StatelessWidget {
  const _PreviewHandwriting();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF10121C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Icon(Icons.gesture, size: 48, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _PreviewVoiceTyping extends StatelessWidget {
  const _PreviewVoiceTyping();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10121C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.surface,
          child: Icon(Icons.mic, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _PreviewSuggestionRow extends StatelessWidget {
  const _PreviewSuggestionRow({required this.chips, required this.active});

  final List<String> chips;
  final String active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1017),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (final c in chips)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        c,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: c == active
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: c == active
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.mic, size: 12, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _MiniKeyboard extends StatelessWidget {
  const _MiniKeyboard({required this.keys});

  final List<List<String>> keys;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxKeys = keys.fold<int>(
          0,
          (v, e) => e.length > v ? e.length : v,
        );
        const gap = 3.0;
        const rowGap = 4.0;
        final padding =
            constraints.hasBoundedHeight && constraints.maxHeight < 90
            ? 8.0
            : 10.0;

        final widthRaw =
            (constraints.maxWidth - padding * 2 - (maxKeys - 1) * gap) /
            maxKeys;
        var keySize = widthRaw;
        if (constraints.hasBoundedHeight) {
          final heightRaw =
              (constraints.maxHeight -
                  padding * 2 -
                  (keys.length - 1) * rowGap) /
              keys.length;
          keySize = keySize < heightRaw ? keySize : heightRaw;
        }
        keySize = keySize.clamp(6.0, 16.0);
        if (constraints.hasBoundedHeight) {
          final totalHeight =
              padding * 2 + keys.length * keySize + (keys.length - 1) * rowGap;
          if (totalHeight > constraints.maxHeight) {
            keySize = (keySize - (totalHeight - constraints.maxHeight)).clamp(
              6.0,
              16.0,
            );
          }
        }

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1017),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var r = 0; r < keys.length; r++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < keys[r].length; i++) ...[
                      _MiniKey(label: keys[r][i], size: keySize),
                      if (i != keys[r].length - 1) const SizedBox(width: gap),
                    ],
                  ],
                ),
                if (r != keys.length - 1) const SizedBox(height: rowGap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MiniKey extends StatelessWidget {
  const _MiniKey({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.key,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: (size * 0.48).clamp(6, 9),
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ThemesPage extends StatelessWidget {
  const ThemesPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Appearance',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _ThemeTile(
              title: 'System',
              subtitle: 'Follow device setting',
              selected: settings.themeMode == AppThemeMode.system,
              onTap: () => settings.setThemeMode(AppThemeMode.system),
            ),
            const SizedBox(height: 10),
            _ThemeTile(
              title: 'Dark',
              subtitle: 'Best for night typing',
              selected: settings.themeMode == AppThemeMode.dark,
              onTap: () => settings.setThemeMode(AppThemeMode.dark),
            ),
            const SizedBox(height: 10),
            _ThemeTile(
              title: 'Light',
              subtitle: 'Bright and clean',
              selected: settings.themeMode == AppThemeMode.light,
              onTap: () => settings.setThemeMode(AppThemeMode.light),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Keyboard height',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Height',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: settings.keyboardHeightFactor,
                    min: 0.45,
                    max: 0.75,
                    onChanged: (v) => settings.setKeyboardHeightFactor(v),
                  ),
                  Text(
                    'Affects both the in-app keyboard and the system keyboard',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Keys',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Show key borders',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Switch(
                    value: settings.showKeyBorders,
                    onChanged: (v) => settings.setShowKeyBorders(v),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class KeyboardPage extends StatefulWidget {
  const KeyboardPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  final ScrollController _scrollController = ScrollController();

  String _text = '';
  String _currentWord = '';
  bool _showCopied = false;
  DateTime? _lastSpaceTapAt;

  String _sugWordCache = '';
  bool _sugModeCache = true;
  List<String> _sugCache = const [];

  List<String> get _suggestions {
    if (widget.settings.layoutMode == KeyboardLayoutMode.malayalam) {
      return const [];
    }
    if (_currentWord == _sugWordCache &&
        widget.settings.isMalayalamMode == _sugModeCache) {
      return _sugCache;
    }
    _sugWordCache = _currentWord;
    _sugModeCache = widget.settings.isMalayalamMode;
    _sugCache = getSuggestions(_currentWord, widget.settings.isMalayalamMode);
    return _sugCache;
  }

  void _appendChar(String ch) {
    if (ch.length == 1 && RegExp(r'[a-zA-Z]').hasMatch(ch)) {
      if (_text.isEmpty || _text.endsWith('. ') || _text.endsWith('\n')) {
        ch = ch.toUpperCase();
      }
    }

    setState(() {
      _text += ch;
      if (ch == ' ') {
        _currentWord = '';
      } else {
        _currentWord += ch;
      }
    });
    _scrollToBottom();
  }

  void _deleteChar() {
    if (_text.isEmpty) return;
    setState(() {
      _text = _text.substring(0, _text.length - 1);
      final parts = _text.split(' ');
      _currentWord = parts.isNotEmpty ? parts.last : '';
    });
    _scrollToBottom();
  }

  void _enter() {
    setState(() {
      _text += '\n';
      _currentWord = '';
    });
    _scrollToBottom();
  }

  void _space() {
    final now = DateTime.now();
    final isDoubleTap =
        _lastSpaceTapAt != null &&
        now.difference(_lastSpaceTapAt!).inMilliseconds < 300;
    _lastSpaceTapAt = now;

    setState(() {
      if (isDoubleTap && _text.endsWith(' ')) {
        _text = '${_text.substring(0, _text.length - 1)}. ';
        _currentWord = '';
        return;
      }

      if (_currentWord.trim().isEmpty) {
        _text += ' ';
        _currentWord = '';
        return;
      }

      if (widget.settings.layoutMode == KeyboardLayoutMode.malayalam) {
        _text += ' ';
        _currentWord = '';
        return;
      }

      if (!widget.settings.isMalayalamMode) {
        _text += ' ';
        _currentWord = '';
        return;
      }

      final commit = _suggestions.isNotEmpty
          ? _suggestions.first
          : _currentWord;
      _text =
          '${_text.substring(0, _text.length - _currentWord.length)}$commit ';
      _currentWord = '';
    });
    _scrollToBottom();
  }

  void _selectSuggestion(String word) {
    if (_currentWord.isEmpty) return;
    setState(() {
      _text = '${_text.substring(0, _text.length - _currentWord.length)}$word ';
      _currentWord = '';
    });
    _scrollToBottom();
  }

  void _toggleMalayalam() {
    widget.settings.setMalayalamMode(!widget.settings.isMalayalamMode);
  }

  Future<void> _openImeSettings() async {
    try {
      await _systemKeyboardChannel.invokeMethod<void>('openImeSettings');
    } catch (_) {}
  }

  Future<void> _showImePicker() async {
    try {
      await _systemKeyboardChannel.invokeMethod<void>('showImePicker');
    } catch (_) {}
  }

  Future<void> _copy() async {
    if (_text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _text));
    if (!mounted) return;
    setState(() => _showCopied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _showCopied = false);
  }

  Future<void> _clear() async {
    if (_text.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Clear text?'),
          content: const Text('This will remove all typed text.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    setState(() {
      _text = '';
      _currentWord = '';
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final target = pos.maxScrollExtent;
      if (!pos.hasPixels) return;
      if ((target - pos.pixels).abs() < 24) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safe = media.viewPadding;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Try EngLam'),
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: EngLamLogo(size: 34),
        ),
        actions: [
          IconButton(
            onPressed: _openImeSettings,
            icon: const Icon(Icons.keyboard, size: 22),
            tooltip: 'Enable Keyboard',
          ),
          IconButton(
            onPressed: _showImePicker,
            icon: const Icon(Icons.keyboard_alt_outlined, size: 22),
            tooltip: 'Select Keyboard',
          ),
          IconButton(
            onPressed: _copy,
            icon: const Icon(Icons.content_copy, size: 20),
            color: _showCopied ? AppColors.primary : null,
            tooltip: 'Copy',
          ),
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline, size: 22),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      controller: _scrollController,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            _text.isEmpty ? 'Type here…' : _text,
                            style: TextStyle(
                              fontSize: 20,
                              height: 1.4,
                              color: _text.isEmpty
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                safe.left,
                0,
                safe.right,
                safe.bottom,
              ),
              child: AnimatedBuilder(
                animation: widget.settings,
                builder: (context, _) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          media.size.height *
                          widget.settings.keyboardHeightFactor,
                    ),
                    child: EngLamKeyboard(
                      currentWord: _currentWord,
                      suggestions: _suggestions,
                      isMalayalamMode: widget.settings.isMalayalamMode,
                      showKeyBorders: widget.settings.showKeyBorders,
                      layoutMode: widget.settings.layoutMode,
                      onToggleMalayalamMode: _toggleMalayalam,
                      onToggleLayoutMode: () {
                        final next = switch (widget.settings.layoutMode) {
                          KeyboardLayoutMode.translit =>
                            KeyboardLayoutMode.malayalam,
                          KeyboardLayoutMode.malayalam =>
                            KeyboardLayoutMode.handwriting,
                          KeyboardLayoutMode.handwriting =>
                            KeyboardLayoutMode.translit,
                        };
                        widget.settings.setLayoutMode(next);
                        if (next == KeyboardLayoutMode.handwriting) {
                          widget.settings.setMalayalamMode(true);
                        }
                      },
                      onInput: _appendChar,
                      onDelete: _deleteChar,
                      onEnter: _enter,
                      onSpace: _space,
                      onSuggestionSelect: _selectSuggestion,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _suggestionDictionary = <String, List<String>>{
  'pinnallathe': ['പിന്നല്ലാതെ', 'Pinnallathe', 'പിന്നല്ലാത'],
  'adipoli': ['അടിപൊളി', 'adipoli', 'അടിപൊളീ'],
  'alle': ['അല്ലെ', 'alle', 'അല്ലേ'],
  'namaskaram': ['നമസ്കാരം', 'namaskaram', 'നമസ്കാരം'],
  'englam': ['എംഗ്ലാം', 'Englam', 'എംഗ്ലം'],
  'manglish': ['മംഗ്ലീഷ്', 'Manglish', 'മംഗ്ലിഷ്'],
  'hello': ['ഹലോ', 'hello', 'ഹെലോ'],
  'kerala': ['കേരളം', 'kerala', 'കേരള'],
  'malayalam': ['മലയാളം', 'malayalam', 'മലയാലം'],
  'ajmal': ['അജ്മൽ', 'ajmal', 'അജ്മാൽ'],
};

final _transliterationRules = <MapEntry<RegExp, String>>[
  MapEntry(RegExp('zh'), 'ഴ്'),
  MapEntry(RegExp('sh'), 'ഷ്'),
  MapEntry(RegExp('ch'), 'ച്'),
  MapEntry(RegExp('th'), 'ത്'),
  MapEntry(RegExp('nj'), 'ഞ്'),
  MapEntry(RegExp('ng'), 'ങ്'),
  MapEntry(RegExp('ph'), 'ഫ്'),
  MapEntry(RegExp('kh'), 'ഖ്'),
  MapEntry(RegExp('gh'), 'ഘ്'),
  MapEntry(RegExp('bh'), 'ഭ്'),
  MapEntry(RegExp('dh'), 'ധ്'),
  MapEntry(RegExp('jh'), 'ഝ്'),
  MapEntry(RegExp('a'), 'ാ'),
  MapEntry(RegExp('e'), 'െ'),
  MapEntry(RegExp('i'), 'ി'),
  MapEntry(RegExp('o'), 'ൊ'),
  MapEntry(RegExp('u'), 'ു'),
  MapEntry(RegExp('b'), 'ബ്'),
  MapEntry(RegExp('c'), 'ക്'),
  MapEntry(RegExp('d'), 'ഡ്'),
  MapEntry(RegExp('f'), 'ഫ്'),
  MapEntry(RegExp('g'), 'ഗ്'),
  MapEntry(RegExp('h'), 'ഹ്'),
  MapEntry(RegExp('j'), 'ജ്'),
  MapEntry(RegExp('k'), 'ക്'),
  MapEntry(RegExp('l'), 'ല്'),
  MapEntry(RegExp('m'), 'മ്'),
  MapEntry(RegExp('n'), 'ന്'),
  MapEntry(RegExp('p'), 'പ്'),
  MapEntry(RegExp('q'), 'ക്യു'),
  MapEntry(RegExp('r'), 'ര്'),
  MapEntry(RegExp('s'), 'സ്'),
  MapEntry(RegExp('t'), 'റ്റ്'),
  MapEntry(RegExp('v'), 'വ്'),
  MapEntry(RegExp('w'), 'വ്'),
  MapEntry(RegExp('x'), 'ക്സ്'),
  MapEntry(RegExp('y'), 'യ്'),
  MapEntry(RegExp('z'), 'സ്'),
];

List<String> getSuggestions(String input, bool isMalayalamMode) {
  final lower = input.trim().toLowerCase();
  if (lower.isEmpty) return const [];

  if (!isMalayalamMode) {
    final cap = input.isEmpty
        ? input
        : input[0].toUpperCase() + input.substring(1).toLowerCase();
    return [lower, cap, input.toUpperCase()];
  }

  final out = <String>[];
  void push(String v) {
    final t = v.trim();
    if (t.isEmpty) return;
    if (!out.contains(t)) out.add(t);
  }

  if (_suggestionDictionary.containsKey(lower)) {
    for (final v in _suggestionDictionary[lower]!) {
      push(v);
    }
    push(input);
    return out;
  }

  for (final key in _suggestionDictionary.keys) {
    if (key.startsWith(lower)) {
      for (final v in _suggestionDictionary[key]!) {
        push(v);
      }
      push(input);
      return out;
    }
  }

  var transliterated = lower;
  for (final rule in _transliterationRules) {
    transliterated = transliterated.replaceAll(rule.key, rule.value);
  }
  transliterated = transliterated
      .replaceFirst(RegExp(r'^ാ'), 'അ')
      .replaceFirst(RegExp(r'^െ'), 'എ')
      .replaceFirst(RegExp(r'^ി'), 'ഇ')
      .replaceFirst(RegExp(r'^ൊ'), 'ഒ')
      .replaceFirst(RegExp(r'^ു'), 'ഉ');

  push(transliterated);
  push('$transliteratedം');
  push(input);
  return out;
}

class EngLamKeyboard extends StatefulWidget {
  const EngLamKeyboard({
    super.key,
    required this.currentWord,
    required this.suggestions,
    required this.isMalayalamMode,
    required this.showKeyBorders,
    required this.layoutMode,
    required this.onToggleMalayalamMode,
    required this.onToggleLayoutMode,
    required this.onInput,
    required this.onDelete,
    required this.onEnter,
    required this.onSpace,
    required this.onSuggestionSelect,
  });

  final String currentWord;
  final List<String> suggestions;
  final bool isMalayalamMode;
  final bool showKeyBorders;
  final KeyboardLayoutMode layoutMode;
  final VoidCallback onToggleMalayalamMode;
  final VoidCallback onToggleLayoutMode;
  final ValueChanged<String> onInput;
  final VoidCallback onDelete;
  final VoidCallback onEnter;
  final VoidCallback onSpace;
  final ValueChanged<String> onSuggestionSelect;

  @override
  State<EngLamKeyboard> createState() => _EngLamKeyboardState();
}

class _EngLamKeyboardState extends State<EngLamKeyboard> {
  static const _numbersRow = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];

  static const _alphaLayout = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  static const _malayalamLayout = [
    ['അ', 'ആ', 'ഇ', 'ഈ', 'ഉ', 'ഊ', 'എ', 'ഏ', 'ഒ', 'ഓ'],
    ['ക', 'ഖ', 'ഗ', 'ഘ', 'ങ', 'ച', 'ഛ', 'ജ', 'ഝ', 'ഞ'],
    ['ട', 'ഠ', 'ഡ', 'ഢ', 'ണ', 'ത', 'ഥ', 'ദ', 'ധ', 'ന'],
    ['പ', 'ഫ', 'ബ', 'ഭ', 'മ', 'യ', 'ര', 'ല', 'വ', 'സ'],
  ];

  static const _symbolsRow2 = [
    '@',
    '#',
    '₹',
    '_',
    '&',
    '-',
    '+',
    '(',
    ')',
    '/',
  ];
  static const _symbolsRow3 = ['*', '"', '\'', ':', ';', '!', '?', '…'];
  static const _symbolsRow4A = ['%', '=', '/', '\\', '|'];
  static const _symbolsRow4B = ['[', ']', '{', '}', '<', '>', '~'];

  bool _isShift = false;
  bool _isCaps = false;
  bool _isSymbols = false;
  bool _isMoreSymbols = false;

  Timer? _deleteDelay;
  Timer? _deleteRepeat;

  final List<List<_HwPoint>> _hwStrokes = [];
  List<_HwPoint> _hwActiveStroke = const [];
  Timer? _hwDebounce;
  bool _hwRecognizing = false;
  List<String> _hwCandidates = const [];

  void _handleKey(String val) {
    if (_isSymbols) {
      widget.onInput(val);
      return;
    }
    var out = val;
    if (_isShift || _isCaps) out = out.toUpperCase();
    widget.onInput(out);
    if (_isShift && !_isCaps) {
      setState(() => _isShift = false);
    }
  }

  void _toggleSymbols() {
    setState(() {
      _isSymbols = !_isSymbols;
      if (!_isSymbols) _isMoreSymbols = false;
      _isShift = false;
      _isCaps = false;
    });
  }

  void _toggleLayout() {
    setState(() {
      _isSymbols = false;
      _isMoreSymbols = false;
      _isShift = false;
      _isCaps = false;
    });
    widget.onToggleLayoutMode();
  }

  void _shift() {
    setState(() {
      if (_isShift) {
        _isCaps = true;
        _isShift = false;
      } else if (_isCaps) {
        _isCaps = false;
        _isShift = false;
      } else {
        _isShift = true;
      }
    });
  }

  void _startDeleteHold() {
    _stopDeleteHold();
    _deleteDelay = Timer(const Duration(milliseconds: 320), () {
      _deleteRepeat = Timer.periodic(const Duration(milliseconds: 55), (_) {
        widget.onDelete();
      });
    });
  }

  void _stopDeleteHold() {
    _deleteDelay?.cancel();
    _deleteDelay = null;
    _deleteRepeat?.cancel();
    _deleteRepeat = null;
  }

  @override
  void dispose() {
    _stopDeleteHold();
    _hwDebounce?.cancel();
    super.dispose();
  }

  void _hwClear() {
    setState(() {
      _hwStrokes.clear();
      _hwActiveStroke = const [];
      _hwCandidates = const [];
      _hwRecognizing = false;
    });
  }

  void _hwScheduleRecognize() {
    _hwDebounce?.cancel();
    _hwDebounce = Timer(const Duration(milliseconds: 320), _hwRecognize);
  }

  Future<void> _hwRecognize() async {
    if (_hwRecognizing) return;
    if (_hwStrokes.isEmpty) {
      if (!mounted) return;
      setState(() => _hwCandidates = const []);
      return;
    }

    setState(() => _hwRecognizing = true);
    try {
      final strokes = _hwStrokes
          .map(
            (s) => s
                .map((p) => {'x': p.x, 'y': p.y, 't': p.t})
                .toList(growable: false),
          )
          .toList(growable: false);
      final raw = await _handwritingChannel.invokeMethod<List<dynamic>>(
        'recognize',
        {'strokes': strokes},
      );
      if (!mounted) return;
      setState(
        () => _hwCandidates =
            raw?.map((e) => e.toString()).toList(growable: false) ?? const [],
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _hwCandidates = const []);
    } finally {
      if (mounted) {
        setState(() => _hwRecognizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.layoutMode == KeyboardLayoutMode.handwriting && !_isSymbols) {
      final layoutLabel = switch (widget.layoutMode) {
        KeyboardLayoutMode.translit => 'അ',
        KeyboardLayoutMode.malayalam => '✍',
        KeyboardLayoutMode.handwriting => 'abc',
      };

      final content = Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          children: [
            Container(
              height: 172,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1017),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onPanStart: (d) {
                    final t = DateTime.now().millisecondsSinceEpoch;
                    setState(
                      () => _hwActiveStroke = [
                        _HwPoint(d.localPosition.dx, d.localPosition.dy, t),
                      ],
                    );
                  },
                  onPanUpdate: (d) {
                    final t = DateTime.now().millisecondsSinceEpoch;
                    setState(() {
                      _hwActiveStroke = [
                        ..._hwActiveStroke,
                        _HwPoint(d.localPosition.dx, d.localPosition.dy, t),
                      ];
                    });
                  },
                  onPanEnd: (_) {
                    if (_hwActiveStroke.isEmpty) return;
                    setState(() {
                      _hwStrokes.add(_hwActiveStroke);
                      _hwActiveStroke = const [];
                    });
                    _hwScheduleRecognize();
                  },
                  child: CustomPaint(
                    painter: _HandwritingPainter(
                      strokes: _hwStrokes,
                      active: _hwActiveStroke,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _KeyButton(
                  label: _isSymbols ? 'ABC' : '?123',
                  isAction: true,
                  minWidth: 72,
                  disablePopup: true,
                  onTap: _toggleSymbols,
                  showBorder: widget.showKeyBorders,
                ),
                const SizedBox(width: 6),
                _KeyButton(
                  label: '⌫',
                  isAction: true,
                  minWidth: 54,
                  disablePopup: true,
                  onTap: () {
                    if (_hwStrokes.isNotEmpty || _hwActiveStroke.isNotEmpty) {
                      _hwClear();
                      return;
                    }
                    widget.onDelete();
                  },
                  showBorder: widget.showKeyBorders,
                ),
                const SizedBox(width: 6),
                _KeyButton(
                  label: 'CLR',
                  isAction: true,
                  minWidth: 62,
                  disablePopup: true,
                  onTap: _hwClear,
                  showBorder: widget.showKeyBorders,
                ),
                const SizedBox(width: 6),
                _KeyButton(
                  label: layoutLabel,
                  isAction: true,
                  minWidth: 52,
                  disablePopup: true,
                  onTap: _toggleLayout,
                  showBorder: widget.showKeyBorders,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _KeyButton(
                    label: '',
                    value: ' ',
                    bgColor: AppColors.key,
                    disablePopup: true,
                    onTap: () {
                      if (_hwStrokes.isNotEmpty && _hwCandidates.isNotEmpty) {
                        widget.onInput(_hwCandidates.first);
                        _hwClear();
                      }
                      widget.onSpace();
                    },
                    showBorder: widget.showKeyBorders,
                    child: Container(
                      alignment: Alignment.center,
                      child: Container(
                        height: 4,
                        width: 90,
                        decoration: BoxDecoration(
                          color: AppColors.keyPressed,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _KeyButton(
                  label: '.',
                  isAction: true,
                  minWidth: 44,
                  onTap: () => _handleKey('.'),
                  showBorder: widget.showKeyBorders,
                ),
                const SizedBox(width: 6),
                _KeyButton(
                  label: '⏎',
                  isPrimary: true,
                  minWidth: 72,
                  disablePopup: true,
                  onTap: () {
                    if (_hwStrokes.isNotEmpty && _hwCandidates.isNotEmpty) {
                      widget.onInput(_hwCandidates.first);
                      _hwClear();
                      return;
                    }
                    widget.onEnter();
                  },
                  showBorder: widget.showKeyBorders,
                ),
              ],
            ),
          ],
        ),
      );

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 24,
              offset: Offset(0, -12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HandwritingCandidateBar(
              candidates: _hwCandidates,
              busy: _hwRecognizing,
              onSelect: (s) {
                widget.onInput(s);
                _hwClear();
              },
              onClear: _hwClear,
            ),
            _EmojiBar(onSelect: widget.onInput),
            content,
          ],
        ),
      );
    }

    final rows = widget.layoutMode == KeyboardLayoutMode.malayalam
        ? _malayalamLayout
        : _alphaLayout;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        children: [
          _KeyRow(
            keys: _isSymbols ? _numbersRow : rows[0],
            onKey: _handleKey,
            showKeyBorders: widget.showKeyBorders,
          ),
          const SizedBox(height: 8),
          _KeyRow(
            keys: _isSymbols ? _symbolsRow2 : rows[1],
            widthFactor: _isSymbols ? null : 0.9,
            onKey: _handleKey,
            labelTransform: _isSymbols
                ? null
                : (s) => (_isShift || _isCaps) ? s.toUpperCase() : s,
            showKeyBorders: widget.showKeyBorders,
          ),
          if (_isSymbols ||
              widget.layoutMode == KeyboardLayoutMode.malayalam) ...[
            const SizedBox(height: 8),
            _KeyRow(
              keys: _isSymbols ? _symbolsRow3 : rows[2],
              widthFactor: 0.9,
              onKey: _handleKey,
              labelTransform: _isSymbols
                  ? null
                  : (s) => (_isShift || _isCaps) ? s.toUpperCase() : s,
              showKeyBorders: widget.showKeyBorders,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _KeyButton(
                label: _isSymbols ? '=\u003c' : '↑',
                isAction: true,
                isActive: _isShift || _isCaps,
                minWidth: 54,
                onTap: _isSymbols
                    ? () => setState(() => _isMoreSymbols = !_isMoreSymbols)
                    : _shift,
                showBorder: widget.showKeyBorders,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _KeyRow(
                  keys: _isSymbols
                      ? (_isMoreSymbols ? _symbolsRow4B : _symbolsRow4A)
                      : (widget.layoutMode == KeyboardLayoutMode.malayalam
                            ? rows[3]
                            : rows[2]),
                  onKey: _handleKey,
                  labelTransform: _isSymbols
                      ? null
                      : (s) => (_isShift || _isCaps) ? s.toUpperCase() : s,
                  showKeyBorders: widget.showKeyBorders,
                ),
              ),
              const SizedBox(width: 6),
              _KeyButton(
                label: '⌫',
                isAction: true,
                minWidth: 54,
                disablePopup: true,
                onPressStart: _startDeleteHold,
                onPressEnd: _stopDeleteHold,
                onTap: widget.onDelete,
                showBorder: widget.showKeyBorders,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _KeyButton(
                label: _isSymbols ? 'ABC' : '?123',
                isAction: true,
                minWidth: 72,
                disablePopup: true,
                onTap: _toggleSymbols,
                showBorder: widget.showKeyBorders,
              ),
              const SizedBox(width: 6),
              _KeyButton(
                label: ',',
                isAction: true,
                minWidth: 44,
                onTap: () => _handleKey(','),
                showBorder: widget.showKeyBorders,
              ),
              const SizedBox(width: 6),
              _KeyButton(
                label: switch (widget.layoutMode) {
                  KeyboardLayoutMode.translit => 'അ',
                  KeyboardLayoutMode.malayalam => '✍',
                  KeyboardLayoutMode.handwriting => 'abc',
                },
                isAction: true,
                minWidth: 52,
                disablePopup: true,
                onTap: _toggleLayout,
                showBorder: widget.showKeyBorders,
              ),
              const SizedBox(width: 6),
              _KeyButton(
                label: 'ma',
                isPrimary: widget.isMalayalamMode,
                isAction: !widget.isMalayalamMode,
                minWidth: 44,
                disablePopup: true,
                onTap: widget.onToggleMalayalamMode,
                showBorder: widget.showKeyBorders,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _KeyButton(
                  label: '',
                  value: ' ',
                  bgColor: AppColors.key,
                  disablePopup: true,
                  onTap: widget.onSpace,
                  showBorder: widget.showKeyBorders,
                  child: Container(
                    alignment: Alignment.center,
                    child: Container(
                      height: 4,
                      width: 90,
                      decoration: BoxDecoration(
                        color: AppColors.keyPressed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _KeyButton(
                label: '.',
                isAction: true,
                minWidth: 44,
                onTap: () => _handleKey('.'),
                showBorder: widget.showKeyBorders,
              ),
              const SizedBox(width: 6),
              _KeyButton(
                label: '⏎',
                isPrimary: true,
                minWidth: 72,
                disablePopup: true,
                onTap: widget.onEnter,
                showBorder: widget.showKeyBorders,
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fixed = [
            _SuggestionBar(
              isMalayalamMode: widget.isMalayalamMode,
              suggestions: widget.layoutMode == KeyboardLayoutMode.malayalam
                  ? const []
                  : widget.suggestions,
              onSelect: widget.onSuggestionSelect,
            ),
            _EmojiBar(onSelect: widget.onInput),
          ];

          if (!constraints.hasBoundedHeight) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [...fixed, content],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...fixed,
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: content,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HwPoint {
  const _HwPoint(this.x, this.y, this.t);

  final double x;
  final double y;
  final int t;
}

class _HandwritingPainter extends CustomPainter {
  const _HandwritingPainter({required this.strokes, required this.active});

  final List<List<_HwPoint>> strokes;
  final List<_HwPoint> active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void drawStroke(List<_HwPoint> pts) {
      if (pts.isEmpty) return;
      if (pts.length == 1) {
        canvas.drawCircle(Offset(pts.first.x, pts.first.y), 2, paint);
        return;
      }
      final path = Path()..moveTo(pts.first.x, pts.first.y);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].x, pts[i].y);
      }
      canvas.drawPath(path, paint);
    }

    for (final s in strokes) {
      drawStroke(s);
    }
    drawStroke(active);
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.active != active;
  }
}

class _HandwritingCandidateBar extends StatelessWidget {
  const _HandwritingCandidateBar({
    required this.candidates,
    required this.busy,
    required this.onSelect,
    required this.onClear,
  });

  final List<String> candidates;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final trailing = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textMuted,
            ),
          )
        : const Icon(
            Icons.delete_outline,
            color: AppColors.textMuted,
            size: 20,
          );

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const _IconBox(icon: Icons.chevron_left),
          Container(
            width: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: const Text(
              'MA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: candidates.isEmpty
                    ? const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Write…',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ]
                    : candidates
                          .take(10)
                          .map(
                            (s) => InkWell(
                              onTap: () => onSelect(s),
                              child: Container(
                                height: double.infinity,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
              ),
            ),
          ),
          InkWell(
            onTap: onClear,
            child: Container(
              width: 44,
              height: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.border)),
              ),
              child: trailing,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({
    required this.isMalayalamMode,
    required this.suggestions,
    required this.onSelect,
  });

  final bool isMalayalamMode;
  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          _IconBox(icon: Icons.chevron_left),
          Container(
            width: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              isMalayalamMode ? 'MA' : 'EN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMalayalamMode
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: suggestions.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'EngLam',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ]
                    : suggestions
                          .take(10)
                          .map(
                            (s) => InkWell(
                              onTap: () => onSelect(s),
                              child: Container(
                                height: double.infinity,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
              ),
            ),
          ),
          _IconBox(icon: Icons.mic_none),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: double.infinity,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Icon(icon, color: AppColors.textMuted, size: 20),
    );
  }
}

class _EmojiBar extends StatelessWidget {
  const _EmojiBar({required this.onSelect});

  final ValueChanged<String> onSelect;

  static const _emojis = [
    '😂',
    '❤️',
    '🙏',
    '🥰',
    '🤣',
    '👍',
    '😭',
    '😁',
    '🫂',
    '👌',
    '🌹',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          const ExcludeSemantics(
            child: Icon(
              Icons.emoji_emotions_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final e = _emojis[i];
                return InkWell(
                  onTap: () => onSelect(e),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                );
              },
            ),
          ),
          const ExcludeSemantics(
            child: Icon(Icons.more_horiz, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.keys,
    required this.onKey,
    required this.showKeyBorders,
    this.widthFactor,
    this.labelTransform,
  });

  final List<String> keys;
  final ValueChanged<String> onKey;
  final bool showKeyBorders;
  final double? widthFactor;
  final String Function(String)? labelTransform;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        for (final k in keys) ...[
          Expanded(
            child: _KeyButton(
              label: labelTransform != null ? labelTransform!(k) : k,
              value: k,
              onTap: () => onKey(k),
              showBorder: showKeyBorders,
            ),
          ),
          if (k != keys.last) const SizedBox(width: 6),
        ],
      ],
    );

    if (widthFactor == null) return row;
    return FractionallySizedBox(widthFactor: widthFactor, child: row);
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.label,
    this.value,
    this.onTap,
    this.child,
    this.isAction = false,
    this.isPrimary = false,
    this.isActive = false,
    this.disablePopup = false,
    this.showBorder = false,
    this.bgColor,
    this.minWidth,
    this.onPressStart,
    this.onPressEnd,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? child;
  final bool isAction;
  final bool isPrimary;
  final bool isActive;
  final bool disablePopup;
  final bool showBorder;
  final Color? bgColor;
  final double? minWidth;
  final VoidCallback? onPressStart;
  final VoidCallback? onPressEnd;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  void _down(TapDownDetails _) async {
    setState(() => _pressed = true);
    await HapticFeedback.lightImpact();
    widget.onPressStart?.call();
  }

  void _up(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onPressEnd?.call();
  }

  void _cancel() {
    setState(() => _pressed = false);
    widget.onPressEnd?.call();
  }

  void _tap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        widget.bgColor ??
        (widget.isPrimary
            ? AppColors.primary
            : widget.isAction
            ? AppColors.actionKey
            : AppColors.key);

    final pressedColor = widget.isPrimary
        ? AppColors.primaryPressed
        : AppColors.keyPressed;
    final isPressed = _pressed || widget.isActive;

    final fg = widget.isPrimary ? Colors.black : Colors.white;
    final labelStyle = TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      color: fg,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minWidth ?? 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _cancel,
        onTap: _tap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isPressed ? pressedColor : base,
                borderRadius: BorderRadius.circular(10),
                border: widget.showBorder
                    ? Border.all(color: AppColors.border)
                    : null,
              ),
              child: widget.child ?? Text(widget.label, style: labelStyle),
            ),
            if (_pressed && !widget.disablePopup && widget.label.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                top: -56,
                child: Center(
                  child: Container(
                    width: 64,
                    height: 72,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: AppColors.keyPressed,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
