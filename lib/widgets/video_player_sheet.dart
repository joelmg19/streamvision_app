import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'live_badge.dart';
import 'quality_badge.dart';
import 'channel_logo.dart';

class VideoPlayerSheet extends StatefulWidget {
  final Channel channel;
  final void Function(int channelId) onFavoriteToggle;
  final bool isFavorite;

  const VideoPlayerSheet({
    super.key,
    required this.channel,
    required this.onFavoriteToggle,
    required this.isFavorite,
  });

  @override
  State<VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<VideoPlayerSheet> {
  bool _isCopied = false;

  void _copyStreamUrl() async {
    if (widget.channel.streamUrl != null) {
      await Clipboard.setData(ClipboardData(text: widget.channel.streamUrl!));
      setState(() => _isCopied = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isCopied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.channel;
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),

        // ── Header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(children: [
            ChannelLogo(channel: ch, size: 52, borderRadius: 14),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ch.name, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Row(children: [
                if (ch.isLive) ...[const LiveBadge(), const SizedBox(width: 8)],
                QualityBadge(quality: ch.quality),
                if (ch.country.isNotEmpty) ...[const SizedBox(width: 8), Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(5), border: Border.all(color: AppColors.border)),
                  child: Text(ch.country, style: AppTextStyles.labelSmall),
                )],
              ]),
            ])),
            GestureDetector(
              onTap: () => widget.onFavoriteToggle(ch.id),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: widget.isFavorite ? AppColors.warning.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.isFavorite ? AppColors.warning.withOpacity(0.3) : AppColors.border),
                ),
                child: Icon(widget.isFavorite ? Icons.star_rounded : Icons.star_border_rounded, size: 20, color: widget.isFavorite ? AppColors.warning : AppColors.textMuted),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Stream info ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            // Group / category
            if (ch.groupTitle != null)
              _InfoRow(icon: Icons.category_rounded, label: 'Categoría', value: ch.groupTitle!),
            if (ch.currentProgram.isNotEmpty && ch.currentProgram != 'En directo')
              _InfoRow(icon: Icons.tv_rounded, label: 'Programa', value: ch.currentProgram),
            _InfoRow(icon: Icons.language_rounded, label: 'País', value: ch.country.isEmpty ? 'Internacional' : ch.country),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Stream URL (for external player) ────────────────────
        if (ch.streamUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.link_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('URL del stream', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, letterSpacing: 0.5)),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ch.streamUrl!, style: AppTextStyles.bodySmall.copyWith(fontFamily: 'monospace'), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _copyStreamUrl,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: _isCopied ? const LinearGradient(colors: [AppColors.success, Color(0xFF059669)]) : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_isCopied ? Icons.check_rounded : Icons.copy_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(_isCopied ? '¡Copiado!' : 'Copiar URL', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),

        const SizedBox(height: 16),

        // ── How to watch tip ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accentPurple.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentViolet),
              const SizedBox(width: 10),
              Expanded(child: Text('Copia la URL y ábrela en VLC, Kodi u otro reproductor compatible con m3u8.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
            ]),
          ),
        ),

        const SizedBox(height: 28),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.bodySmall),
        Expanded(child: Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
