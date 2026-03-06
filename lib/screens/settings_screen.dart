import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoplay = true;
  bool _hd = true;
  bool _notifications = true;
  bool _parentalControl = false;
  bool _hardwareAccel = true;
  bool _subtitles = false;
  double _bandwidth = 25;
  String _quality = 'auto';
  String _language = 'es';

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentPurple.withOpacity(0.3),
                        AppColors.accentCyan.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.accentPurple.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: AppColors.accentViolet,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ajustes', style: AppTextStyles.headlineLarge),
                    Text('Personaliza StreamVision',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Quality selector ─────────────────────────────────────
        SliverToBoxAdapter(
          child: _SettingsSection(
            icon: Icons.tv_rounded,
            iconColor: AppColors.accentPurple,
            title: 'Calidad de Video',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona la calidad predeterminada',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['auto', '4K', 'FHD', 'HD', 'SD'].map((q) {
                    final isSelected = _quality == q;
                    return GestureDetector(
                      onTap: () => setState(() => _quality = q),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppColors.accentPurple
                                        .withOpacity(0.35),
                                    AppColors.accentCyan.withOpacity(0.2),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentPurple.withOpacity(0.4)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check_rounded,
                                  size: 13, color: AppColors.accentViolet),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              q == 'auto' ? 'Automática' : q,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // ── Bandwidth ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SettingsSection(
            icon: Icons.wifi_rounded,
            iconColor: AppColors.accentCyan,
            title: 'Ancho de Banda',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Límite de descarga',
                        style: AppTextStyles.bodySmall),
                    Text(
                      '${_bandwidth.round()} Mbps',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: AppColors.accentPurple,
                    inactiveTrackColor:
                        Colors.white.withOpacity(0.12),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _bandwidth,
                    min: 1,
                    max: 100,
                    onChanged: (v) =>
                        setState(() => _bandwidth = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 Mbps', style: AppTextStyles.bodySmall),
                    Text('100 Mbps', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Language ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SettingsSection(
            icon: Icons.language_rounded,
            iconColor: AppColors.warning,
            title: 'Idioma',
            child: Wrap(
              spacing: 8,
              children: [
                _LanguageOption(code: 'es', flag: '🇪🇸', label: 'Español'),
                _LanguageOption(code: 'en', flag: '🇬🇧', label: 'English'),
                _LanguageOption(code: 'fr', flag: '🇫🇷', label: 'Français'),
                _LanguageOption(code: 'de', flag: '🇩🇪', label: 'Deutsch'),
              ].map((opt) {
                final isSelected = _language == opt.code;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _language = opt.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.warning.withOpacity(0.12)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.warning.withOpacity(0.35)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_rounded,
                              size: 12, color: AppColors.warning),
                          const SizedBox(width: 4),
                        ],
                        Text(opt.flag,
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          opt.label,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Toggles ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SettingsSection(
            icon: Icons.play_circle_rounded,
            iconColor: AppColors.accentPurple,
            title: 'Reproducción',
            child: Column(
              children: [
                _ToggleRow(
                  title: 'Reproducción automática',
                  subtitle: 'Inicia el canal seleccionado automáticamente',
                  value: _autoplay,
                  onChanged: (v) => setState(() => _autoplay = v),
                ),
                _ToggleRow(
                  title: 'Alta definición',
                  subtitle: 'Priorizar streams en HD o superior',
                  value: _hd,
                  onChanged: (v) => setState(() => _hd = v),
                ),
                _ToggleRow(
                  title: 'Aceleración por hardware',
                  subtitle: 'Mejor rendimiento en dispositivos compatibles',
                  value: _hardwareAccel,
                  onChanged: (v) =>
                      setState(() => _hardwareAccel = v),
                ),
                _ToggleRow(
                  title: 'Subtítulos automáticos',
                  subtitle: 'Activar cuando estén disponibles',
                  value: _subtitles,
                  onChanged: (v) => setState(() => _subtitles = v),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _SettingsSection(
            icon: Icons.notifications_rounded,
            iconColor: AppColors.warning,
            title: 'Notificaciones y Seguridad',
            child: Column(
              children: [
                _ToggleRow(
                  title: 'Notificaciones push',
                  subtitle: 'Avisos sobre programas favoritos',
                  value: _notifications,
                  onChanged: (v) =>
                      setState(() => _notifications = v),
                ),
                _ToggleRow(
                  title: 'Control parental',
                  subtitle: 'Bloquear contenido para adultos',
                  value: _parentalControl,
                  onChanged: (v) =>
                      setState(() => _parentalControl = v),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),

        // ── About ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SettingsSection(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.info,
            title: 'Acerca de StreamVision',
            child: Column(
              children: [
                ...[
                  {'label': 'Versión', 'value': '3.2.1'},
                  {'label': 'Build', 'value': '20260225'},
                  {'label': 'Licencia', 'value': 'Premium'},
                  {'label': 'Canales activos', 'value': '30'},
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['label']!,
                            style: AppTextStyles.bodyMedium),
                        Text(
                          item['value']!,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Text(
                            'Buscar actualizaciones',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Settings Section ───────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SettingsSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: AppTextStyles.headlineSmall),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppColors.border,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle Row ─────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.settingTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.settingSubtitle),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.accentPurple,
              inactiveTrackColor: Colors.white.withOpacity(0.12),
              inactiveThumbColor: Colors.white.withOpacity(0.6),
              trackOutlineColor:
                  MaterialStateProperty.all(Colors.transparent),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ── Helper types ───────────────────────────────────────────────────────────────

class _LanguageOption {
  final String code;
  final String flag;
  final String label;

  const _LanguageOption({
    required this.code,
    required this.flag,
    required this.label,
  });
}
