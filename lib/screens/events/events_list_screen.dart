import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/event_card.dart';
import '../../data/models/volunteer_event.dart';
import '../../state/events_model.dart';
import '../shell/app_shell.dart';
import 'event_form_dialog.dart';

/// Екран «Заходи» (макет S-05, FR-09): пошук у верхній панелі, фільтри
/// «Категорія», «Статус» і «Мої заходи», сортування та сітка карток.
///
/// Побудований на CustomScrollView: заголовок із фільтрами прокручується
/// разом із сіткою (SliverGrid).
class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  // Контролер пошуку — ефемерний стан екрана, а сам запит
  // зберігається в EventsModel.
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: context.read<EventsModel>().query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<EventsModel>();
    final events = model.visibleEvents;

    return Column(
      children: [
        AppTopBar(
          title: 'Заходи',
          center: _SearchField(controller: _searchController),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: model.load,
            child: CustomScrollView(
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                  sliver: SliverToBoxAdapter(child: _Header()),
                ),
                if (model.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (model.errorMessage != null && events.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      icon: Icons.cloud_off,
                      text: model.errorMessage!,
                      actionLabel: 'Повторити',
                      onAction: model.load,
                    ),
                  )
                else if (events.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      icon: Icons.search_off,
                      text: 'Заходів за цими умовами не знайдено',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 560,
                        mainAxisExtent: 180,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return EventListCard(
                          event: event,
                          confirmedCount: model.confirmedCount(event.id),
                          isOrganizer: model.isOrganizer(event),
                          onTap: () => AppShell.openEvent(context, event.id),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<EventsModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: model.setQuery,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        hintText: 'Пошук заходів',
        prefixIcon: const Icon(Icons.search, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        suffixIcon: model.query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Очистити',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  model.setQuery('');
                },
              ),
      ),
    );
  }
}

/// Заголовок сторінки, кнопка створення та рядок фільтрів.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<EventsModel>();
    final theme = Theme.of(context);
    final count = model.visibleEvents.length;

    // «Мої заходи» — окремий перемикач, решта значень — у меню «Статус».
    final statusFilters =
        EventDateFilter.values.where((f) => f != EventDateFilter.mine);
    final isMine = model.dateFilter == EventDateFilter.mine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Волонтерські заходи',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Знайдіть можливість зробити добру справу поруч',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => showEventFormDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Створити захід'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MenuChip<EventCategory?>(
                    label: model.category?.label ?? 'Усі категорії',
                    active: true,
                    value: model.category,
                    options: [
                      (null, 'Усі категорії'),
                      for (final c in EventCategory.values) (c, c.label),
                    ],
                    onSelected: model.setCategory,
                  ),
                  _MenuChip<EventDateFilter>(
                    label: isMine || model.dateFilter == EventDateFilter.all
                        ? 'Статус'
                        : model.dateFilter.label,
                    active: !isMine && model.dateFilter != EventDateFilter.all,
                    value: model.dateFilter,
                    options: [for (final f in statusFilters) (f, f.label)],
                    onSelected: model.setDateFilter,
                  ),
                  FilterChip(
                    label: const Text('Мої заходи'),
                    selected: isMine,
                    shape: const StadiumBorder(),
                    onSelected: (selected) => model.setDateFilter(
                      selected ? EventDateFilter.mine : EventDateFilter.all,
                    ),
                  ),
                  _MenuChip<EventSort>(
                    label: model.sort.label,
                    icon: Icons.sort,
                    active: false,
                    value: model.sort,
                    options: [for (final s in EventSort.values) (s, s.label)],
                    onSelected: model.setSort,
                  ),
                ],
              ),
            ),
            Text(
              'Знайдено $count ${_plural(count)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  static String _plural(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'захід';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'заходи';
    }
    return 'заходів';
  }
}

/// Чип із випадним меню: «Усі категорії ▾», «Статус ▾», сортування.
class _MenuChip<T> extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  const _MenuChip({
    required this.label,
    required this.active,
    required this.value,
    required this.options,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = active ? colorScheme.onPrimary : colorScheme.onSurface;

    return PopupMenuButton<int>(
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (index) => onSelected(options[index].$1),
      itemBuilder: (_) => [
        for (var i = 0; i < options.length; i++)
          CheckedPopupMenuItem(
            value: i,
            checked: options[i].$1 == value,
            child: Text(options[i].$2),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: foreground),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
