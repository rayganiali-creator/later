import 'package:flutter_test/flutter_test.dart';
import 'package:later/domain/models.dart';

import 'harness.dart';
import 'helpers.dart';

void main() {
  test('a note with a reminder is scheduled and counted on the Notes shelf', () async {
    final e = await TestEnv.create(
      settings: readySettings,
      items: [
        item('n', due: DateTime(2026, 10, 7, 18), hasTime: true, reminder: true)
            .copyWith(type: ItemType.note, description: 'متن یادداشت'),
      ],
      now: DateTime(2026, 10, 7, 8),
    );
    final c = e.controller;
    await c.init();
    await c.syncReminders();
    expect(c.dashboardCounts().notes, 1);
    final s = e.gateway.scheduled.values.firstWhere((s) => s.reminder.itemId == 'n');
    expect(s.reminder.body, 'متن یادداشت');
  });

  test('syncing reminders never cancels everything (shown notifications survive)', () async {
    final e = await TestEnv.create(
      settings: readySettings,
      items: [item('a', due: DateTime(2026, 10, 7, 18), hasTime: true, reminder: true)],
      now: DateTime(2026, 10, 7, 8),
    );
    await e.controller.init();
    await e.controller.syncReminders();
    await e.controller.syncReminders();
    expect(e.gateway.cancelAllCalls, 0);
    expect(e.gateway.scheduled.length, 1);
    await e.controller.delete('a');
    await e.controller.syncReminders();
    expect(e.gateway.scheduled, isEmpty);
  });

  test('note stages: archived counts as dropped, not done', () {
    expect(ItemStages.statusFor(ItemType.note, ItemStages.noteArchived), ItemStatus.dropped);
    expect(ItemStages.statusFor(ItemType.note, 0), ItemStatus.active);
  });
}
