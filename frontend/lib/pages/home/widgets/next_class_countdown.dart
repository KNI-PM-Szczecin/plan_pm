import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/lecture_model.dart';
import 'package:plan_pm/global/app_time.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/service/database_service.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class NextClassCountdown extends StatefulWidget {
  const NextClassCountdown({super.key});

  @override
  State<NextClassCountdown> createState() => _NextClassCountdownState();
}

class _NextClassCountdownState extends State<NextClassCountdown> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  LectureModel? _nextLecture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNextLecture();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNextLecture() async {
    final lectures = await DatabaseService.instance.fetchLectures();
    final now = AppTime.now();

    // Filter future lectures and sort by date
    final futureLectures = lectures
        .where((l) => l.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (mounted) {
      setState(() {
        _nextLecture = futureLectures.isNotEmpty ? futureLectures.first : null;
        _isLoading = false;
        _updateCountdown();
      });
    }
  }

  void _updateCountdown() {
    if (_nextLecture == null) return;

    final now = AppTime.now();
    final difference = _nextLecture!.date.difference(now);

    if (difference.isNegative) {
      // If the class just started, reload to find the next one
      _loadNextLecture();
    } else {
      if (mounted) {
        setState(() {
          _timeLeft = difference;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return "${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m";
    } else if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s";
    } else {
      return "${duration.inMinutes}m ${duration.inSeconds % 60}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_nextLecture == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppColor.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColor.outline, width: 1),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.nextClassCountdownTitle,
                  style: TextStyle(
                    color: AppColor.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  LucideIcons.clock,
                  color: AppColor.primary,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _nextLecture!.name,
              style: TextStyle(
                color: AppColor.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 14,
                  color: AppColor.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${_nextLecture!.startTime} • ${_nextLecture!.location ?? l10n.roomNaN}",
                    style: TextStyle(
                      color: AppColor.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(_timeLeft),
                  style: TextStyle(
                    color: AppColor.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Text(
                    l10n.nextClassCountdownRemaining,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
