import '../core/util/dates.dart';
import 'models.dart';
import 'snooze.dart';

/// Pure state transitions for an item. They return the new item and the
/// history event to record; persistence is done by the caller. Keeping this
/// separate lets the UI controller and the background notification-action
/// handler share exactly the same rules.
class Transition {
  const Transition(this.item, this.event);
  final LaterItem item;
  final ItemEvent event;
}

class Transitions {
  const Transitions._();

  static int _waited(LaterItem i, DateTime now) =>
      Dates.daysBetween(i.createdAt, now).clamp(0, 100000);

  static Transition complete(LaterItem i, DateTime now) => Transition(
        i.copyWith(
          status: ItemStatus.done,
          completedAt: now,
          droppedAt: null,
          updatedAt: now,
        ),
        ItemEvent(
          itemId: i.id,
          type: EventType.completed,
          at: now,
          categoryId: i.categoryId,
          daysWaited: _waited(i, now),
        ),
      );

  /// "بی‌خیالش شدم": set aside without a feeling of failure.
  static Transition drop(LaterItem i, DateTime now) => Transition(
        i.copyWith(
          status: ItemStatus.dropped,
          droppedAt: now,
          completedAt: null,
          updatedAt: now,
        ),
        ItemEvent(
          itemId: i.id,
          type: EventType.dropped,
          at: now,
          categoryId: i.categoryId,
          daysWaited: _waited(i, now),
        ),
      );

  static Transition snooze(LaterItem i, SnoozeTarget target, DateTime now) =>
      Transition(
        i.copyWith(
          dueAt: target.dueAt,
          hasTime: target.dueAt == null ? false : target.hasTime,
          snoozeCount: i.snoozeCount + 1,
          // Snoozing is an explicit decision: restart the "waiting" clock.
          lastKeptAt: now,
          // A reminder without a date makes no sense.
          reminderEnabled: target.dueAt == null ? false : i.reminderEnabled,
          updatedAt: now,
        ),
        ItemEvent(
          itemId: i.id,
          type: EventType.snoozed,
          at: now,
          categoryId: i.categoryId,
        ),
      );

  /// "نگه دار" in the stale review: keep as-is, restart the waiting clock.
  static Transition keep(LaterItem i, DateTime now) => Transition(
        i.copyWith(lastKeptAt: now, updatedAt: now),
        ItemEvent(
          itemId: i.id,
          type: EventType.kept,
          at: now,
          categoryId: i.categoryId,
        ),
      );

  static LaterItem reopen(LaterItem i, DateTime now) => i.copyWith(
        status: ItemStatus.active,
        completedAt: null,
        droppedAt: null,
        updatedAt: now,
      );
}
