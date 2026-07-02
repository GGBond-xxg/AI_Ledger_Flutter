import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../l10n/translation_service.dart';

class LedgerTextField extends StatelessWidget {
  const LedgerTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: maxLines > 1 ? maxLines : 1,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: AppTheme.inputColor(context),
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
          contentPadding: EdgeInsets.fromLTRB(18, maxLines > 1 ? 18 : 15, 18, maxLines > 1 ? 18 : 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.42)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.42)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.60), width: 1.2),
          ),
        ),
      ),
    );
  }
}

class LedgerDropdownField<T> extends StatelessWidget {
  const LedgerDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    DropdownMenuItem<T>? selectedItem;
    for (final item in items) {
      if (item.value == value) {
        selectedItem = item;
        break;
      }
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: Material(
        color: AppTheme.inputColor(context),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () async {
            final selected = await _showPicker(context);
            if (selected != null) onChanged(selected);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.42)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                        child: selectedItem?.child ?? Text(value.toString()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<T?> _showPicker(BuildContext context) async {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Get.bottomSheet<T>(
      DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.34,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            trSelectLabel(label),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back<void>(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(14, 0, 14, 18 + MediaQuery.paddingOf(context).bottom),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = item.value == value;
                        return Material(
                          color: selected
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.58)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: AppTheme.isDark(context) ? 0.34 : 0.48),
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Get.back<T>(result: item.value),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DefaultTextStyle.merge(
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      child: item.child,
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    opacity: selected ? 1 : 0,
                                    duration: const Duration(milliseconds: 160),
                                    child: Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
