// Pole wyboru z listy w stylu makiety: wiersz z etykietą nad wartością i ↕,
// po tapnięciu menu z haczykiem przy wybranej opcji. Kładziony w
// [AppGroupedSection]. Zastępuje DropdownMenu z polem tekstowym — tu nie ma
// czego wpisywać, jest tylko wybór.
//
// [AppMenuField] — jeden wybór (menu zamyka się po tapnięciu).
// [AppMultiMenuField] — kilka naraz (haczyki, menu zostaje otwarte, w wierszu
// lista wybranych kodów); używane w wyborze grup.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';

/// Szerokość menu przy wierszu inline (1d) — węższe, przy prawej krawędzi.
const double _inlineMenuWidth = 250;

MenuStyle _menuStyle(BuildContext context, double menuWidth) => MenuStyle(
  backgroundColor: WidgetStatePropertyAll(AppColor.groupedSurface),
  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
  elevation: const WidgetStatePropertyAll(8),
  shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.2)),
  shape: WidgetStatePropertyAll(
    RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: AppColor.separator),
    ),
  ),
  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
  // Menu tak szerokie jak pole — długie nazwy kierunków się mieszczą.
  minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
  maximumSize: WidgetStatePropertyAll(
    Size(menuWidth, MediaQuery.sizeOf(context).height * 0.5),
  ),
);

Widget _menuItem({
  required String label,
  required bool checked,
  required VoidCallback onPressed,
  required double maxWidth,
  bool muted = false,
  bool closeOnActivate = true,
}) {
  return MenuItemButton(
    onPressed: onPressed,
    closeOnActivate: closeOnActivate,
    leadingIcon: SizedBox(
      width: 20,
      child: checked
          ? Icon(LucideIcons.check, size: 18, color: AppColor.primary)
          : null,
    ),
    style: MenuItemButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      minimumSize: const Size.fromHeight(44),
    ),
    child: ConstrainedBox(
      // Szerokość panelu wynika z pozycji (MenuStyle.minimumSize jest
      // ignorowane), więc to tutaj trzymamy menu w [maxWidth]. 68 = padding
      // pozycji 2×16 + haczyk 20 + odstęp.
      constraints: BoxConstraints.tightFor(width: maxWidth - 68),
      child: Text(
        label,
        style: AppTextStyle.body.copyWith(
          color: muted ? AppColor.labelSecondary : AppColor.onSurface,
        ),
      ),
    ),
  );
}

/// Wiersz inline z menu wielokrotnego wyboru: tytuł po lewej, po prawej
/// wybrane etykiety po przecinku (albo [placeholder]) i ↕. Pozycje menu
/// przełączają się haczykiem i nie zamykają menu; [clearLabel] odznacza
/// wszystkie.
class AppMultiMenuField<T> extends StatelessWidget {
  const AppMultiMenuField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.options,
    required this.optionLabel,
    required this.selected,
    required this.onToggled,
    this.clearLabel,
    this.onCleared,
    this.enabled = true,
  });

  final String label;
  final String placeholder;
  final List<T> options;
  final String Function(T option) optionLabel;

  /// Zaznaczone opcje (podzbiór [options]).
  final Set<T> selected;
  final ValueChanged<T> onToggled;
  final String? clearLabel;
  final VoidCallback? onCleared;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && options.isNotEmpty;
    final chosen = options.where(selected.contains).map(optionLabel).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = _inlineMenuWidth.clamp(0.0, constraints.maxWidth);
        return MenuAnchor(
          alignmentOffset: Offset(constraints.maxWidth - menuWidth - 8, 0),
          style: _menuStyle(context, menuWidth),
          menuChildren: [
            if (clearLabel != null)
              _menuItem(
                label: clearLabel!,
                checked: chosen.isEmpty,
                onPressed: onCleared ?? () {},
                maxWidth: menuWidth,
                muted: true,
                closeOnActivate: false,
              ),
            for (final option in options)
              _menuItem(
                label: optionLabel(option),
                checked: selected.contains(option),
                onPressed: () => onToggled(option),
                maxWidth: menuWidth,
                closeOnActivate: false,
              ),
          ],
          builder: (context, controller, _) => AppListRow(
            title: label,
            value: chosen.isEmpty ? placeholder : chosen.join(', '),
            accessory: AppListRowAccessory.menu,
            onTap: isEnabled
                ? () =>
                      controller.isOpen ? controller.close() : controller.open()
                : null,
          ),
        );
      },
    );
  }
}

class AppMenuField<T> extends StatelessWidget {
  const AppMenuField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.options,
    required this.optionLabel,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    this.clearLabel,
    this.onCleared,
    this.inline = false,
  });

  final String label;

  /// Tekst w miejscu wartości, dopóki nic nie wybrano.
  final String placeholder;
  final List<T> options;
  final String Function(T option) optionLabel;
  final T? selected;
  final ValueChanged<T> onSelected;
  final bool enabled;

  /// Pierwsza pozycja menu, która czyści wybór (np. „Nie wybrano").
  /// `null` = wyboru nie da się cofnąć.
  final String? clearLabel;
  final VoidCallback? onCleared;

  /// `true` = etykieta jako tytuł, wybór jako wartość po prawej (wiersz grupy
  /// w 1d). `false` = etykieta nad wybraną wartością (pole formularza w 1c).
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final hasValue = selected != null;
    final isEnabled = enabled && options.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Pole formularza: menu na całą szerokość (długie nazwy kierunków).
        // Wiersz inline: węższe menu przy prawej krawędzi, pod wartością (1d).
        final menuWidth = inline
            ? _inlineMenuWidth.clamp(0.0, constraints.maxWidth)
            : constraints.maxWidth;
        return MenuAnchor(
          alignmentOffset: Offset(
            constraints.maxWidth - menuWidth - (inline ? 8 : 0),
            0,
          ),
          style: _menuStyle(context, menuWidth),
          menuChildren: [
            if (clearLabel != null)
              _menuItem(
                label: clearLabel!,
                checked: selected == null,
                onPressed: onCleared ?? () {},
                maxWidth: menuWidth,
                muted: true,
              ),
            for (final option in options)
              _menuItem(
                label: optionLabel(option),
                checked: option == selected,
                onPressed: () => onSelected(option),
                maxWidth: menuWidth,
              ),
          ],
          builder: (context, controller, _) {
            final toggle = isEnabled
                ? () =>
                      controller.isOpen ? controller.close() : controller.open()
                : null;
            final valueText = hasValue
                ? optionLabel(selected as T)
                : placeholder;
            return inline
                ? AppListRow(
                    title: label,
                    value: valueText,
                    accessory: AppListRowAccessory.menu,
                    onTap: toggle,
                  )
                : AppListRow(
                    label: label,
                    title: valueText,
                    // Placeholder w labelSecondary: tertiary (30% krycia)
                    // na ciemnej karcie dawał ok. 2:1 i był nieczytelny.
                    // Tertiary zostaje tylko dla pola nieaktywnego.
                    titleColor: !isEnabled
                        ? AppColor.labelTertiary
                        : hasValue
                        ? null
                        : AppColor.labelSecondary,
                    accessory: AppListRowAccessory.menu,
                    onTap: toggle,
                  );
          },
        );
      },
    );
  }
}
