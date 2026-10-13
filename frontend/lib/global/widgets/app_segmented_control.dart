// Przełącznik 2–4 opcji w pigułce (rok, stopień, tryb studiów, rola).
// Zaznaczenie przesuwa się animowanie i ma kolor akcentu z białym tekstem —
// świadome odstępstwo od białego segmentu z makiety, żeby wybór wyglądał jak
// zwykły przycisk (decyzja właściciela). Opcje z [disabled] są wyszarzone,
// ale widoczne — tak jak w ProgramAvailability niedostępne lata/stopnie.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';

class AppSegment<T> {
  const AppSegment({required this.value, required this.label});

  final T value;
  final String label;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.disabled = const {},
    this.height = 32,
  });

  final List<AppSegment<T>> segments;

  /// `null` = nic nie jest jeszcze wybrane.
  final T? selected;
  final ValueChanged<T> onChanged;
  final Set<T> disabled;
  final double height;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final index = segments.indexWhere((s) => s.value == selected);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        color: AppColor.fillTertiary,
        shape: const StadiumBorder(),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / segments.length;
          return SizedBox(
            height: height,
            child: Stack(
              children: [
                if (index >= 0)
                  AnimatedPositioned(
                    duration: _duration,
                    curve: Curves.easeOutCubic,
                    left: segmentWidth * index,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: AppColor.primary,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (final segment in segments)
                      Expanded(child: _segment(segment)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _segment(AppSegment<T> segment) {
    final isDisabled = disabled.contains(segment.value);
    final isSelected = segment.value == selected;
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !isDisabled,
      inMutuallyExclusiveGroup: true,
      child: AppPressable(
        shape: const StadiumBorder(),
        onTap: isDisabled || isSelected
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged(segment.value);
              },
        child: Center(
          child: Text(
            segment.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.subheadlineEmphasized.copyWith(
              color: isSelected
                  ? Colors.white
                  : isDisabled
                  ? AppColor.labelTertiary
                  : AppColor.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
