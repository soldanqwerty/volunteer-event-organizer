import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/event_card.dart';
import '../../data/models/volunteer_event.dart';
import '../../state/events_model.dart';
import 'event_details_screen.dart';
import 'event_form_dialog.dart';

/// Екран «Заходи» (макет S-05): пошук, фільтр за датою (зокрема
/// «Мої заходи»), фільтр за категорією, сортування та сітка карток.
///
/// Побудований на CustomScrollView: шапка з фільтрами прокручується
/// разом із сіткою (SliverGrid), а не займає місце постійно.
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

  void _openDetails(VolunteerEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(eventId: event.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<EventsModel>();
    final events = model.visibleEvents;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEventFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Створити захід'),
      ),
      body: RefreshIndicator(
        onRefresh: model.load,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              sliver: SliverToBoxAdapter(
                child: _Header(searchController: _searchController),
              ),
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
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 96),
                sliver: SliverGrid.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisExtent: 270,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final footnote = model.isOrganizer(event)
                        ? 'Ви організатор'
                        : '${model.confirmedCount(event.id)}/'
                            '${event.participantLimit} учасників';
                    return EventCard(
                      event: event,
                      width: null,
                      footnote: footnote,
                      onTap: () => _openDetails(event),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Заголовок, пошук і фільтри.
class _Header extends StatelessWidget {
  final TextEditingController searchController;

  const _Header({required this.searchController});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<EventsModel>();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Заходи', style: textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Знайдено: ${model.visibleEvents.length}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: searchController,
                onChanged: model.setQuery,
                decoration: InputDecoration(
                  hintText: 'Пошук за назвою або місцем',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: model.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Очистити',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            searchController.clear();
                            model.setQuery('');
                          },
                        ),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<EventDateFilter>(
                // Ключ перестворює поле, коли фільтр відновлено зі сховища.
                key: ValueKey(model.dateFilter),
                initialValue: model.dateFilter,
                decoration: const InputDecoration(labelText: 'Дата'),
                items: [
                  for (final f in EventDateFilter.values)
                    DropdownMenuItem(value: f, child: Text(f.label)),
                ],
                onChanged: (value) => model.setDateFilter(value!),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<EventSort>(
                key: ValueKey(model.sort),
                initialValue: model.sort,
                decoration: const InputDecoration(labelText: 'Сортування'),
                items: [
                  for (final s in EventSort.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (value) => model.setSort(value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Усі категорії'),
              selected: model.category == null,
              onSelected: (_) => model.setCategory(null),
            ),
            for (final category in EventCategory.values)
              ChoiceChip(
                avatar: CircleAvatar(
                  radius: 5,
                  backgroundColor: category.color,
                ),
                label: Text(category.label),
                selected: model.category == category,
                onSelected: (_) => model.setCategory(category),
              ),
          ],
        ),
      ],
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
