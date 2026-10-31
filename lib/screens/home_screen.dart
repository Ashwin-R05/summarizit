import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:summarizit/services/summarizer_service.dart';
import 'package:summarizit/services/file_export_service.dart';
import 'package:summarizit/services/document_scanner_service.dart';
import 'package:summarizit/theme/theme_provider.dart';
import 'package:summarizit/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summarizit/widgets/gradient_button.dart';
import 'package:summarizit/widgets/summary_card.dart';

class HomeScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SharedPreferences prefs;

  const HomeScreen({super.key, required this.themeProvider, required this.prefs});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late SummarizerService _summarizer;
  final FileExportService _fileExport = FileExportService();
  final DocumentScannerService _scannerService = DocumentScannerService();
  final ScrollController _scrollController = ScrollController();

  List<String> _bullets = [];
  bool _isLoading = false;
  bool _showResult = false;

  late AnimationController _resultAnimController;
  late Animation<double> _resultFadeAnim;
  late Animation<Offset> _resultSlideAnim;

  // Floating orb animation
  late AnimationController _orbController;
  late Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();
    _summarizer = SummarizerService(prefs: widget.prefs);
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _resultFadeAnim = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeOut,
    );
    _resultSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _resultAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _orbAnim = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_orbController);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _resultAnimController.dispose();
    _orbController.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  bool get _isDark => widget.themeProvider.isDark;
  int get _wordCount {
    final text = _textController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _textController.text.length;

  void _onSummarize() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showSnack('Please paste or type some text first.');
      return;
    }
    if (_wordCount < 30) {
      _showSnack('Enter at least 30 words for a meaningful summary.');
      return;
    }

    setState(() {
      _isLoading = true;
      _showResult = false;
    });
    _resultAnimController.reset();

    await Future.delayed(const Duration(milliseconds: 900));

    final result = await _summarizer.summarizeAsync(text);
    if (!mounted) return;

    if (result.notice != null) {
      _showSnack(result.notice!);
    }

    setState(() {
      _bullets = result.bullets;
      _isLoading = false;
      _showResult = true;
    });
    _resultAnimController.forward();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showSettingsDialog() async {
    final storedKey = await _summarizer.getApiKey() ?? '';
    if (!mounted) return;

    final apiKeyController = TextEditingController(text: storedKey);
    bool useAi = widget.prefs.getBool(AppConstants.keyUseAiSummarization) ?? false;
    bool obscureKey = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardOverlay(_isDark),
              title: Text('Settings', style: TextStyle(color: AppColors.text(_isDark))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text('Use AI Summarization', style: TextStyle(color: AppColors.text(_isDark))),
                    value: useAi,
                    onChanged: (val) {
                      setDialogState(() {
                        useAi = val;
                      });
                    },
                  ),
                  if (useAi)
                    TextField(
                      controller: apiKeyController,
                      obscureText: obscureKey,
                      style: TextStyle(color: AppColors.text(_isDark)),
                      decoration: InputDecoration(
                        labelText: 'Gemini API Key',
                        labelStyle: TextStyle(color: AppColors.textSecondary(_isDark)),
                        hintText: 'Enter your API key',
                        hintStyle: TextStyle(color: AppColors.textSecondary(_isDark).withValues(alpha: 0.5)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureKey ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary(_isDark),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureKey = !obscureKey;
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(_isDark))),
                ),
                TextButton(
                  onPressed: () async {
                    final trimmedKey = apiKeyController.text.trim();
                    await _summarizer.saveApiKey(trimmedKey);
                    await widget.prefs.setBool(AppConstants.keyUseAiSummarization, useAi);
                    await widget.prefs.remove(AppConstants.keyGeminiApiKey);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Save', style: TextStyle(color: AppColors.primaryPurple)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: _isDark
            ? const Color(0xFF2A2A4A)
            : AppColors.primaryPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;
    return Scaffold(
      backgroundColor: AppColors.bg(dark),
      body: Stack(
        children: [
          // ── Animated floating orbs (background decoration) ──
          _buildFloatingOrbs(dark),
          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildTopBar(dark),
                  const SizedBox(height: 28),
                  _buildHeader(dark),
                  const SizedBox(height: 32),
                  _buildInputCard(dark),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: 'Summarize',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: _isLoading,
                    isDark: dark,
                    onPressed: _onSummarize,
                  ),
                  const SizedBox(height: 32),
                  if (_showResult) ...[
                    SlideTransition(
                      position: _resultSlideAnim,
                      child: FadeTransition(
                        opacity: _resultFadeAnim,
                        child: Column(
                          children: [
                            SummaryCard(bullets: _bullets, isDark: dark),
                            const SizedBox(height: 20),
                            _buildExportButtons(dark),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating background orbs ──
  Widget _buildFloatingOrbs(bool dark) {
    return AnimatedBuilder(
      animation: _orbAnim,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: 80 + 30 * math.sin(_orbAnim.value),
              right: -40 + 20 * math.cos(_orbAnim.value),
              child: _orb(120, AppColors.primaryPurple, dark, 0.12),
            ),
            Positioned(
              top: 350 + 25 * math.cos(_orbAnim.value + 1),
              left: -30 + 15 * math.sin(_orbAnim.value + 2),
              child: _orb(90, AppColors.accentTeal, dark, 0.10),
            ),
            Positioned(
              bottom: 200 + 20 * math.sin(_orbAnim.value + 3),
              right: 30 + 20 * math.cos(_orbAnim.value + 1),
              child: _orb(70, AppColors.accentPink, dark, 0.08),
            ),
          ],
        );
      },
    );
  }

  Widget _orb(double size, Color color, bool dark, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: dark ? opacity : opacity * 0.5),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  // ── Top bar (theme toggle & settings) ──
  Widget _buildTopBar(bool dark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardOverlay(dark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(dark)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: AppColors.textSecondary(dark),
                  size: 22,
                ),
                onPressed: _showSettingsDialog,
              ),
              Container(
                width: 1,
                height: 24,
                color: AppColors.border(dark),
              ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) =>
                      RotationTransition(turns: anim, child: child),
                  child: Icon(
                    dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(dark),
                    color: dark ? AppColors.accentOrange : AppColors.primaryPurple,
                    size: 22,
                  ),
                ),
                onPressed: () {
                  widget.themeProvider.toggleTheme();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header ──
  Widget _buildHeader(bool dark) {
    return Column(
      children: [
        // App icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.primaryGradient,
          ).createShader(bounds),
          child: const Text(
            'SummarizIt',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Paste your article and get an instant AI-powered summary',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary(dark),
            letterSpacing: 0.2,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Input card ──
  Widget _buildInputCard(bool dark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardOverlay(dark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(dark), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(dark),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Text',
                  style: TextStyle(
                    color: AppColors.text(dark),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (_textController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _textController.clear();
                      setState(() {
                        _showResult = false;
                        _bullets = [];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.clear_rounded,
                            size: 14,
                            color: Colors.red.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.red.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Text field
          TextField(
            controller: _textController,
            maxLines: 10,
            minLines: 6,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              color: AppColors.text(dark).withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.65,
            ),
            cursorColor: AppColors.primaryPurple,
            decoration: InputDecoration(
              hintText: 'Paste your article, paragraph, or any long text here…',
              hintStyle: TextStyle(
                color: AppColors.textSecondary(dark).withValues(alpha: 0.6),
                fontSize: 15,
              ),
              contentPadding: const EdgeInsets.all(20),
              border: InputBorder.none,
            ),
          ),
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.02)
                  : AppColors.lightBg.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                _statChip(
                  Icons.short_text_rounded,
                  '$_wordCount words',
                  AppColors.primaryPurple,
                  dark,
                ),
                const SizedBox(width: 16),
                _statChip(
                  Icons.text_fields_rounded,
                  '$_charCount chars',
                  AppColors.accentTeal,
                  dark,
                ),
                const Spacer(),

                // Add File/Image Upload buttons
                IconButton(
                  icon: Icon(Icons.image, color: AppColors.textSecondary(dark), size: 20),
                  onPressed: () async {
                     final text = await _scannerService.pickAndExtractTextFromImage(ImageSource.gallery);
                     if (text != null && text.isNotEmpty) {
                       setState(() {
                         _textController.text += "\n$text";
                       });
                     } else {
                        _showSnack("No text recognized or action cancelled.");
                     }
                  },
                  tooltip: 'Upload Image (OCR)',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.file_upload, color: AppColors.textSecondary(dark), size: 20),
                  onPressed: () async {
                     final text = await _scannerService.pickAndExtractTextFromFile();
                     if (text != null && text.isNotEmpty) {
                       setState(() {
                         _textController.text += "\n$text";
                       });
                     } else {
                        _showSnack("Could not read file or action cancelled.");
                     }
                  },
                  tooltip: 'Upload Text File',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),

                // Min requirement indicator
                if (_wordCount > 0 && _wordCount < 30)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Min 30 words',
                      style: TextStyle(
                        color: AppColors.accentOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_wordCount >= 30)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.accentTeal,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color, bool dark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(dark),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Export buttons ──
  Widget _buildExportButtons(bool dark) {
    return Row(
      children: [
        Expanded(
          child: _exportButton(
            icon: Icons.description_outlined,
            label: 'Download TXT',
            color: AppColors.accentTeal,
            dark: dark,
            onTap: () => _fileExport.exportAsTxt(_bullets),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _exportButton(
            icon: Icons.file_present_rounded,
            label: 'Download DOCX',
            color: AppColors.primaryPurple,
            dark: dark,
            onTap: () => _fileExport.exportAsDocx(_bullets),
          ),
        ),
      ],
    );
  }

  Widget _exportButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardOverlay(dark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: dark ? 0.08 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.text(dark),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
