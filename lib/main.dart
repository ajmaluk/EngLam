import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'englam_logo.dart';

const _systemKeyboardChannel = MethodChannel('englam/system_keyboard');

void main() {
  runApp(const EngLamApp());
}

class EngLamApp extends StatelessWidget {
  const EngLamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EngLam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.surface, foregroundColor: Colors.white),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('EngLam Keyboard'),
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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            children: [
              const SizedBox(height: 6),
              const Center(child: EngLamLogo(size: 84)),
              const SizedBox(height: 14),
              Text('EngLam', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Malayalam transliteration keyboard', style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Privacy-first', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            'This keyboard does not collect sensitive information. Android may show a standard warning when enabling third‑party keyboards.',
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _StepCard(
                step: 'Step 1',
                title: 'Activate Keyboard',
                subtitle: 'Enable EngLam in system keyboard settings',
                buttonText: 'Activate Keyboard',
                onTap: _openImeSettings,
              ),
              const SizedBox(height: 12),
              _StepCard(
                step: 'Step 2',
                title: 'Select Keyboard',
                subtitle: 'Choose EngLam as your current input method',
                buttonText: 'Select Keyboard',
                onTap: _showImePicker,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KeyboardPage()));
                },
                child: const Text('Try in app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  final String step;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

class KeyboardPage extends StatefulWidget {
  const KeyboardPage({super.key});

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  final ScrollController _scrollController = ScrollController();

  String _text = '';
  String _currentWord = '';
  bool _isMalayalamMode = true;
  bool _showCopied = false;
  DateTime? _lastSpaceTapAt;

  String _sugWordCache = '';
  bool _sugModeCache = true;
  List<String> _sugCache = const [];

  List<String> get _suggestions {
    if (_currentWord == _sugWordCache && _isMalayalamMode == _sugModeCache) {
      return _sugCache;
    }
    _sugWordCache = _currentWord;
    _sugModeCache = _isMalayalamMode;
    _sugCache = getSuggestions(_currentWord, _isMalayalamMode);
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
    final isDoubleTap = _lastSpaceTapAt != null && now.difference(_lastSpaceTapAt!).inMilliseconds < 300;
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

      if (!_isMalayalamMode) {
        _text += ' ';
        _currentWord = '';
        return;
      }

      final commit = _suggestions.isNotEmpty ? _suggestions.first : _currentWord;
      _text = '${_text.substring(0, _text.length - _currentWord.length)}$commit ';
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
    setState(() {
      _isMalayalamMode = !_isMalayalamMode;
    });
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
          backgroundColor: AppColors.surface,
          title: const Text('Clear text?'),
          content: const Text('This will remove all typed text.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Clear')),
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
      _scrollController.animateTo(target, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
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
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            _text.isEmpty ? 'Type here…' : _text,
                            style: TextStyle(
                              fontSize: 20,
                              height: 1.4,
                              color: _text.isEmpty ? AppColors.textMuted : Colors.white,
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
              padding: EdgeInsets.fromLTRB(safe.left, 0, safe.right, safe.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: media.size.height * 0.58),
                child: EngLamKeyboard(
                  currentWord: _currentWord,
                  suggestions: _suggestions,
                  isMalayalamMode: _isMalayalamMode,
                  onToggleMalayalamMode: _toggleMalayalam,
                  onInput: _appendChar,
                  onDelete: _deleteChar,
                  onEnter: _enter,
                  onSpace: _space,
                  onSuggestionSelect: _selectSuggestion,
                ),
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
    final cap = input.isEmpty ? input : input[0].toUpperCase() + input.substring(1).toLowerCase();
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
    required this.onToggleMalayalamMode,
    required this.onInput,
    required this.onDelete,
    required this.onEnter,
    required this.onSpace,
    required this.onSuggestionSelect,
  });

  final String currentWord;
  final List<String> suggestions;
  final bool isMalayalamMode;
  final VoidCallback onToggleMalayalamMode;
  final ValueChanged<String> onInput;
  final VoidCallback onDelete;
  final VoidCallback onEnter;
  final VoidCallback onSpace;
  final ValueChanged<String> onSuggestionSelect;

  @override
  State<EngLamKeyboard> createState() => _EngLamKeyboardState();
}

class _EngLamKeyboardState extends State<EngLamKeyboard> {
  static const _alphaLayout = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  static const _symbolsRow2 = ['@', '#', '₹', '_', '&', '-', '+', '(', ')', '/'];
  static const _symbolsRow3 = ['*', '"', '\'', ':', ';', '!', '?', '…'];
  static const _symbolsRow4A = ['%', '=', '/', '\\', '|'];
  static const _symbolsRow4B = ['[', ']', '{', '}', '<', '>', '~'];

  bool _isShift = false;
  bool _isCaps = false;
  bool _isSymbols = false;
  bool _isMoreSymbols = false;

  Timer? _deleteDelay;
  Timer? _deleteRepeat;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        children: [
          _KeyRow(
            keys: _alphaLayout[0],
            onKey: _handleKey,
          ),
          const SizedBox(height: 8),
          _KeyRow(
            keys: _isSymbols ? _symbolsRow2 : _alphaLayout[1],
            onKey: _handleKey,
            labelTransform: _isSymbols ? null : (s) => (_isShift || _isCaps) ? s.toUpperCase() : s,
          ),
          const SizedBox(height: 8),
          _KeyRow(
            keys: _isSymbols ? _symbolsRow3 : _alphaLayout[2],
            widthFactor: 0.9,
            onKey: _handleKey,
            labelTransform: _isSymbols ? null : (s) => (_isShift || _isCaps) ? s.toUpperCase() : s,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _KeyButton(
                label: _isSymbols ? '=\u003c' : '↑',
                isAction: true,
                isActive: _isShift || _isCaps,
                minWidth: 54,
                onTap: _isSymbols ? () => setState(() => _isMoreSymbols = !_isMoreSymbols) : _shift,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _KeyRow(
                  keys: _isSymbols ? (_isMoreSymbols ? _symbolsRow4B : _symbolsRow4A) : _alphaLayout[3],
                  onKey: _handleKey,
                  labelTransform: _isSymbols ? null : (s) => (_isShift || _isCaps) ? s.toUpperCase() : s,
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
              ),
              const SizedBox(width: 6),
              _KeyButton(
                label: ',',
                isAction: true,
                minWidth: 44,
                onTap: () => _handleKey(','),
              ),
              const SizedBox(width: 6),
              _KeyButton(
                label: 'മ',
                isPrimary: widget.isMalayalamMode,
                isAction: !widget.isMalayalamMode,
                minWidth: 44,
                disablePopup: true,
                onTap: widget.onToggleMalayalamMode,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _KeyButton(
                  label: '',
                  value: ' ',
                  bgColor: AppColors.key,
                  disablePopup: true,
                  onTap: widget.onSpace,
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
              ),
              const SizedBox(width: 6),
              _KeyButton(
                label: '⏎',
                isPrimary: true,
                minWidth: 72,
                disablePopup: true,
                onTap: widget.onEnter,
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
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, -12)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fixed = [
            _SuggestionBar(
              isMalayalamMode: widget.isMalayalamMode,
              suggestions: widget.suggestions,
              onSelect: widget.onSuggestionSelect,
            ),
            _EmojiBar(onSelect: widget.onInput),
          ];

          if (!constraints.hasBoundedHeight) {
            return Column(mainAxisSize: MainAxisSize.min, children: [...fixed, content]);
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
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
            child: Text(
              isMalayalamMode ? 'ML' : 'EN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMalayalamMode ? AppColors.primary : AppColors.textMuted,
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
                            style: TextStyle(color: Color(0xFF777777), fontWeight: FontWeight.w600),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: AppColors.border)),
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
      width: 44,
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

  static const _emojis = ['😂', '❤️', '🙏', '🥰', '🤣', '👍', '😭', '😁', '🫂', '👌', '🌹'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          const Icon(Icons.emoji_emotions_outlined, color: AppColors.textMuted, size: 20),
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
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                );
              },
            ),
          ),
          const Icon(Icons.more_horiz, color: AppColors.textMuted, size: 20),
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
    this.widthFactor,
    this.labelTransform,
  });

  final List<String> keys;
  final ValueChanged<String> onKey;
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
    final base = widget.bgColor ??
        (widget.isPrimary
            ? AppColors.primary
            : widget.isAction
                ? AppColors.actionKey
                : AppColors.key);

    final pressedColor = widget.isPrimary ? AppColors.primaryPressed : AppColors.keyPressed;
    final isPressed = _pressed || widget.isActive;

    final fg = widget.isPrimary ? Colors.black : Colors.white;
    final labelStyle = TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: fg);

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
                        BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 10)),
                      ],
                    ),
                    child: Text(
                      widget.label,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
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
