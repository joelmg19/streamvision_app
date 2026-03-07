import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/channel_logo.dart';

class EpgScreen extends StatefulWidget {
  final void Function(Channel) onChannelTap;
  const EpgScreen({super.key, required this.onChannelTap});
  @override State<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends State<EpgScreen> {
  int _currentHour = DateTime.now().hour;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelProvider>(builder: (context, provider, _) {
      final channels = provider.filteredChannels.take(20).toList();

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Guía de Programación', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 2),
            Text('EPG — ${channels.length} canales', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 14),
            // Hour navigation
            Row(children: [
              _HourBtn(icon: Icons.chevron_left_rounded, onTap: () => setState(() => _currentHour = (_currentHour - 1).clamp(0, 23))),
              const SizedBox(width: 8),
              Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(24, (h) {
                final isNow = h == DateTime.now().hour;
                final isSelected = h == _currentHour;
                return GestureDetector(onTap: () => setState(() => _currentHour = h),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isSelected ? AppColors.accentPurple.withOpacity(0.3) : isNow ? AppColors.success.withOpacity(0.1) : Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? AppColors.accentPurple.withOpacity(0.4) : Colors.transparent)),
                    child: Text('${h.toString().padLeft(2, '0')}:00', style: AppTextStyles.labelSmall.copyWith(color: isSelected ? AppColors.textPrimary : isNow ? AppColors.success : AppColors.textMuted)),
                  ),
                );
              })))),
              const SizedBox(width: 8),
              _HourBtn(icon: Icons.chevron_right_rounded, onTap: () => setState(() => _currentHour = (_currentHour + 1).clamp(0, 23))),
              const SizedBox(width: 8),
              GestureDetector(onTap: () => setState(() => _currentHour = DateTime.now().hour), child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.success.withOpacity(0.2))),
                child: Row(children: [const Icon(Icons.access_time_rounded, size: 12, color: AppColors.success), const SizedBox(width: 4), Text('Ahora', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success))]),
              )),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        Expanded(child: provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
            : channels.isEmpty
                ? Center(child: Text('Sin canales', style: AppTextStyles.bodyMedium))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: channels.length,
                    itemBuilder: (context, i) {
                      final ch = channels[i];
                      return _EpgRow(channel: ch, currentHour: _currentHour, onTap: () => widget.onChannelTap(ch));
                    },
                  )),
      ]);
    });
  }
}

class _EpgRow extends StatelessWidget {
  final Channel channel;
  final int currentHour;
  final VoidCallback onTap;
  const _EpgRow({required this.channel, required this.currentHour, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          // Channel col
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
            child: Row(children: [
              ChannelLogo(channel: channel, size: 32, borderRadius: 8),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(channel.name, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(channel.country, style: AppTextStyles.bodySmall),
              ])),
            ]),
          ),
          // Program slots
          Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _ProgramSlot(title: channel.currentProgram.isNotEmpty ? channel.currentProgram : 'En directo', time: '${currentHour.toString().padLeft(2, '0')}:00', isLive: true, width: 160),
            _ProgramSlot(title: channel.nextProgram.isNotEmpty ? channel.nextProgram : 'A continuación', time: '${(currentHour + 1).clamp(0, 23).toString().padLeft(2, '0')}:00', isLive: false, width: 140),
            _ProgramSlot(title: 'En espera', time: '${(currentHour + 2).clamp(0, 23).toString().padLeft(2, '0')}:00', isLive: false, width: 120),
          ]))),
        ]),
      ),
    );
  }
}

class _ProgramSlot extends StatelessWidget {
  final String title;
  final String time;
  final bool isLive;
  final double width;
  const _ProgramSlot({required this.title, required this.time, required this.isLive, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: isLive ? LinearGradient(colors: [AppColors.accentPurple.withOpacity(0.35), AppColors.accentCyan.withOpacity(0.2)]) : null,
        color: isLive ? null : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isLive ? AppColors.accentPurple.withOpacity(0.4) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, style: AppTextStyles.labelMedium.copyWith(color: isLive ? AppColors.textPrimary : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(time, style: AppTextStyles.bodySmall),
      ]),
    );
  }
}

class _HourBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HourBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Icon(icon, size: 18, color: AppColors.textSecondary)));
}
