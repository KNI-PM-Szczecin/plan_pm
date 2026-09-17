// Przełącznik radio-button — jeden aktywny przycisk z grupy.
// Wybrany element renderuje [FilledButton], pozostałe [OutlinedButton].
// Jest w pełni sterowany: stan wyboru trzyma rodzic, bo o tym, które opcje
// w ogóle istnieją, decyduje dostępność planów ([ProgramAvailability]) i wybór
// bywa czyszczony spoza tego widżetu.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

class ButtonSwitch extends StatelessWidget {
  const ButtonSwitch({
    super.key,
    required this.icon,
    required this.label,
    required this.buttonAmount,
    required this.buttonLabels,
    required this.onValueChanged,
    this.selectedIndex,
    this.enabledIndices,
  });

  final IconData icon;
  final String label;
  final int buttonAmount;
  final List<String> buttonLabels;
  final void Function(int) onValueChanged;

  /// Indeks aktywnego przycisku; null = nic nie wybrano.
  final int? selectedIndex;

  /// Indeksy, które wolno kliknąć; null = wszystkie. Opcje spoza zbioru są
  /// widoczne, ale wyszarzone — student widzi, że taki rok/stopień istnieje,
  /// tylko nie dla jego kierunku.
  final Set<int>? enabledIndices;

  bool _isEnabled(int index) =>
      enabledIndices == null || enabledIndices!.contains(index);

  @override
  Widget build(BuildContext context) {
    final ButtonStyle unselectedStyle = OutlinedButton.styleFrom(
      backgroundColor: AppColor.surface,
      side: BorderSide(color: AppColor.outline), // outline color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      disabledForegroundColor: AppColor.onSurfaceVariant.withAlpha(90),
    );

    final ButtonStyle selectedStyle = FilledButton.styleFrom(
      backgroundColor: AppColor.primary,
      foregroundColor: AppColor.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColor.onBackgroundVariant, fontSize: 14),
        ),
        const SizedBox(height: 5),
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < buttonAmount; i++)
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: selectedIndex == i
                      ? FilledButton(
                          style: selectedStyle,
                          onPressed: () => onValueChanged(i),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              buttonLabels[i],
                              maxLines: 1,
                              style: TextStyle(color: AppColor.onPrimary),
                            ),
                          ),
                        )
                      : OutlinedButton(
                          style: unselectedStyle,
                          onPressed: _isEnabled(i)
                              ? () => onValueChanged(i)
                              : null,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              buttonLabels[i],
                              maxLines: 1,
                              style: TextStyle(
                                color: _isEnabled(i)
                                    ? AppColor.onSurface
                                    : AppColor.onSurfaceVariant.withAlpha(90),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
