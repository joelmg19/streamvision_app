import 'package:flutter/material.dart';
import '../data/channels_data.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/channel_logo.dart';
import '../widgets/video_player_sheet.dart';

class EpgScreen extends StatefulWidget {
  final List<Channel> channels;
  final void Function(int channelId) onFavoriteToggle;

  const EpgScreen({
    super.key,
    required this.channels,
    required this.onFavoriteToggle,
  });

  @override
  State<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends State<EpgScreen> {
  int _selectedDay = 0; // 0 = today, 1 = tomorrow, -1 = yesterday
  int _currentHour = DateTime.now().hour;

  final List<_DayOption> _dayOptions = const [
    _DayOption(value: -1, label: 'Ayer'),
    _DayOption(value: 0, label: 'Hoy'),
    _DayOption(value: 1, label: 'Mañana'),
    _DayOption(value: 2, label: 'Pasado'),
  ];

  List<int> get _visibleHours {
    final start = _currentHour.clamp(0, 18);
    return List.generate(6, (i) => start + i);
  }

  void _openPlayer(Channel channel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoPlayerSheet(
        channel: channel,
        onFavoriteToggle: widget.onFavoriteToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedChannels = widget.channels.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Guía de Programación',
                  style: AppTextStyles.headlineLarge),
              const SizedBox(height: 2),
              Text(
                'EPG — Electronic Program Guide',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),

              // Day selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _dayOptions.map((day) {
                    final isSelected = _selectedDay == day.value;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDay = day.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentPurple.withOpacity(0.25)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentPurple.withOpacity(0.4)
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          day.label,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.accentViolet
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Hour navigation
              Row(
                children: [
                  _HourNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => setState(() =>
                        _currentHour = (_currentHour - 3).clamp(0, 18)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(20, (h) {
                          final isCurrentHour = h == DateTime.now().hour;
                          final isSelected = h == _currentHour;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _currentHour = h),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentPurple
                                        .withOpacity(0.3)
                                    : isCurrentHour
                                        ? AppColors.success
                                            .withOpacity(0.1)
                                        : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accentPurple
                                          .withOpacity(0.4)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                '${h.toString().padLeft(2, '0')}:00',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : isCurrentHour
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                  fontWeight: isCurrentHour
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HourNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => setState(() =>
                        _currentHour = (_currentHour + 3).clamp(0, 18)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _currentHour = DateTime.now().hour),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Ahora',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── EPG Grid ─────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _EpgGrid(
                channels: displayedChannels,
                visibleHours: _visibleHours,
                onChannelTap: _openPlayer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── EPG Grid ───────────────────────────────────────────────────────────────────

class _EpgGrid extends StatelessWidget {
  final List<Channel> channels;
  final List<int> visibleHours;
  final void Function(Channel) onChannelTap;

  const _EpgGrid({
    required this.channels,
    required this.visibleHours,
    required this.onChannelTap,
  });

  static const double _channelColWidth = 140;
  static const double _hourWidth = 110;
  static const double _rowHeight = 64;

  @override
  Widget build(BuildContext context) {
    final totalWidth =
        _channelColWidth + visibleHours.length * _hourWidth;

    return SizedBox(
      width: totalWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time header
          _TimeHeader(
            visibleHours: visibleHours,
            channelColWidth: _channelColWidth,
            hourWidth: _hourWidth,
          ),

          // Channel rows
          ...channels.map((ch) {
            final entries = ChannelsData.epgData[ch.id] ?? [];
            return _EpgRow(
              channel: ch,
              entries: entries,
              visibleHours: visibleHours,
              channelColWidth: _channelColWidth,
              hourWidth: _hourWidth,
              rowHeight: _rowHeight,
              onChannelTap: onChannelTap,
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TimeHeader extends StatelessWidget {
  final List<int> visibleHours;
  final double channelColWidth;
  final double hourWidth;

  const _TimeHeader({
    required this.visibleHours,
    required this.channelColWidth,
    required this.hourWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Row(
        children: [
          SizedBox(
            width: channelColWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                'CANAL',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          ...visibleHours.map((h) {
            final isNow = h == DateTime.now().hour;
            return Container(
              width: hourWidth,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Text(
                '${h.toString().padLeft(2, '0')}:00',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isNow ? AppColors.success : AppColors.textMuted,
                  fontWeight:
                      isNow ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EpgRow extends StatelessWidget {
  final Channel channel;
  final List<EpgEntry> entries;
  final List<int> visibleHours;
  final double channelColWidth;
  final double hourWidth;
  final double rowHeight;
  final void Function(Channel) onChannelTap;

  const _EpgRow({
    required this.channel,
    required this.entries,
    required this.visibleHours,
    required this.channelColWidth,
    required this.hourWidth,
    required this.rowHeight,
    required this.onChannelTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleEntries = entries.where((e) {
      final h = int.parse(e.time.split(':')[0]);
      return visibleHours.contains(h) ||
          (h < visibleHours.first && h + (e.durationMinutes ~/ 60) >= visibleHours.first);
    }).toList();

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Channel info column
          GestureDetector(
            onTap: () => onChannelTap(channel),
            child: Container(
              width: channelColWidth,
              height: rowHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  ChannelLogo(
                    channelId: channel.id,
                    logoText: channel.logo,
                    size: 32,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          channel.name,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          channel.country,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Program slots
          Expanded(
            child: SizedBox(
              height: rowHeight,
              child: Row(
                children: visibleEntries.isNotEmpty
                    ? visibleEntries.take(3).map((entry) {
                        return _ProgramSlot(
                          entry: entry,
                          hourWidth: hourWidth,
                          rowHeight: rowHeight,
                          onTap: () => onChannelTap(channel),
                        );
                      }).toList()
                    : [
                        Center(
                          child: Text(
                            'Sin información',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                        )
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramSlot extends StatelessWidget {
  final EpgEntry entry;
  final double hourWidth;
  final double rowHeight;
  final VoidCallback onTap;

  const _ProgramSlot({
    required this.entry,
    required this.hourWidth,
    required this.rowHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final slotWidth =
        (entry.durationMinutes / 60 * hourWidth).clamp(80.0, hourWidth * 2.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: slotWidth,
        height: rowHeight - 10,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: entry.isLive
              ? LinearGradient(
                  colors: [
                    AppColors.accentPurple.withOpacity(0.35),
                    AppColors.accentCyan.withOpacity(0.2),
                  ],
                )
              : null,
          color: entry.isLive ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: entry.isLive
                ? AppColors.accentPurple.withOpacity(0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.title,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: entry.isLive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${entry.time} · ${entry.durationMinutes}min',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            if (entry.isLive)
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.liveRed,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Helper types ──────────────────────────────────────────────────────────────

class _DayOption {
  final int value;
  final String label;

  const _DayOption({required this.value, required this.label});
}

class _HourNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HourNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
