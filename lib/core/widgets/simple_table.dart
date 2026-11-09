import 'package:flutter/material.dart';

/// Проста таблиця з заголовками колонок у стилі макета: колонки
/// задаються як (назва, flex).
class SimpleTable extends StatelessWidget {
  final List<(String, int)> columns;
  final List<List<Widget>> rows;

  /// Необов'язкова дія при натисканні на рядок (за індексом рядка).
  final ValueChanged<int>? onRowTap;

  const SimpleTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant;

    Widget buildRow(List<Widget> cells) => Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              Expanded(
                flex: columns[i].$2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: cells[i],
                ),
              ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: buildRow([
            for (final (title, _) in columns)
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: border),
                InkWell(
                  onTap: onRowTap == null ? null : () => onRowTap!(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: buildRow(rows[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
