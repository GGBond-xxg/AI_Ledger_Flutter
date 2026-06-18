part of '../home_page.dart';

class _SortIconButton extends StatelessWidget {
  const _SortIconButton({required this.mode, required this.onTap, required this.onSelected});

  final _SortMode mode;
  final VoidCallback onTap;
  final ValueChanged<_SortMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) async {
        final selected = await showMenu<_SortMode>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: _SortMode.values
              .map(
                (item) => PopupMenuItem<_SortMode>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(_sortModeIcon(item), size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_sortModeLabel(item))),
                      if (item == mode) const Icon(Icons.check_rounded, size: 18),
                    ],
                  ),
                ),
              )
              .toList(),
        );
        if (selected != null) onSelected(selected);
      },
      child: _IconCircleButton(icon: _sortModeIcon(mode), onTap: onTap),
    );
  }
}

_SortMode _nextSortMode(_SortMode mode) {
  return switch (mode) {
    _SortMode.nameAsc => _SortMode.nameDesc,
    _SortMode.nameDesc => _SortMode.amountDesc,
    _SortMode.amountDesc => _SortMode.amountAsc,
    _SortMode.amountAsc => _SortMode.nameAsc,
  };
}

String _sortModeLabel(_SortMode mode) {
  return switch (mode) {
    _SortMode.nameAsc => '名称 A-Z',
    _SortMode.nameDesc => '名称 Z-A',
    _SortMode.amountDesc => '金额从大到小',
    _SortMode.amountAsc => '金额从小到大',
  };
}

IconData _sortModeIcon(_SortMode mode) {
  return switch (mode) {
    _SortMode.nameAsc => Icons.sort_by_alpha_rounded,
    _SortMode.nameDesc => Icons.sort_by_alpha_rounded,
    _SortMode.amountDesc => Icons.sort_rounded,
    _SortMode.amountAsc => Icons.sort_rounded,
  };
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.labels, required this.selectedIndex, required this.onSelected});

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return FilterChip(
            selected: selected,
            showCheckmark: false,
            label: Text(labels[index]),
            onSelected: (_) => onSelected(index),
          );
        },
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SurfaceInk extends StatelessWidget {
  const _SurfaceInk({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: _surfaceDecoration(context, radius: 18),
          child: child,
        ),
      ),
    );
  }
}

class _TonalIcon extends StatelessWidget {
  const _TonalIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.sheetBackground(context),
        ),
      ),
    );
  }
}


class _ActionSheetTile extends StatelessWidget {
  const _ActionSheetTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceInk(
      onTap: onTap,
      child: Row(
        children: [
          _TonalIcon(icon: icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle, this.actionText, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _surfaceDecoration(context, radius: 22),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (actionText != null && onTap != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(onPressed: onTap, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900)),
    );
  }
}
