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

  /// Appends "stage changed to X now" to the item's status history (kept for
  /// the shelves that show it; capped so it never grows without bound).
  static LaterItem track(LaterItem i, DateTime now) {
    if (i.type == ItemType.task || i.type == ItemType.person) return i;
    final h = [
      for (final e in i.stageHistory) [e.$1.millisecondsSinceEpoch, e.$2],
      [now.millisecondsSinceEpoch, i.stage],
    ];
    final cut = h.length > 200 ? h.sublist(h.length - 200) : h;
    return i.withExtra('history', cut);
  }

  static Transition complete(LaterItem i, DateTime now) => Transition(
        track(
            i.copyWith(
              status: ItemStatus.done,
              stage: ItemStages.doneStage(i.type),
              inbox: false,
              completedAt: now,
              droppedAt: null,
              updatedAt: now,
            ),
            now),
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
        track(
            i.copyWith(
              status: ItemStatus.dropped,
              stage: ItemStages.dropStage(i.type),
              inbox: false,
              droppedAt: now,
              completedAt: null,
              updatedAt: now,
            ),
            now),
        ItemEvent(
          itemId: i.id,
          type: EventType.dropped,
          at: now,
          categoryId: i.categoryId,
          daysWaited: _waited(i, now),
        ),
      );

  /// Moves a typed item to another stage (read -> reading, idea -> thinking...)
  /// keeping the generic status, timestamps and history in sync.
  static Transition setStage(LaterItem i, int stage, DateTime now) {
    final status = ItemStages.statusFor(i.type, stage);
    var base = i.copyWith(
      stage: stage,
      status: status,
      inbox: false,
      completedAt: status == ItemStatus.done ? (i.completedAt ?? now) : null,
      droppedAt: status == ItemStatus.dropped ? (i.droppedAt ?? now) : null,
      updatedAt: now,
    );
    // Finishing something means 100 %.
    if (status == ItemStatus.done && (i.type == ItemType.podcast || i.type == ItemType.course)) {
      base = base.withExtra('progress', 100);
    }
    base = track(base, now);
    final type = switch (status) {
      ItemStatus.done => EventType.completed,
      ItemStatus.dropped => EventType.dropped,
      ItemStatus.active => i.status == ItemStatus.active ? EventType.moved : EventType.reopened,
    };
    return Transition(
      base,
      ItemEvent(
        itemId: i.id,
        type: type,
        at: now,
        categoryId: i.categoryId,
        daysWaited: type == EventType.moved || type == EventType.reopened ? null : _waited(i, now),
      ),
    );
  }

  /// Puts an item on another shelf ("this is actually a wishlist item").
  static Transition moveToType(LaterItem i, ItemType type, DateTime now) => Transition(
        track(
            i.copyWith(
              type: type,
              stage: 0,
              status: ItemStatus.active,
              inbox: false,
              completedAt: null,
              droppedAt: null,
              updatedAt: now,
            ),
            now),
        ItemEvent(itemId: i.id, type: EventType.moved, at: now, categoryId: i.categoryId),
      );

  /// Opening a capsule / future message. Repeating messages re-arm themselves.
  static Transition openSealed(LaterItem i, DateTime now, {DateTime? nextUnlock}) {
    if (nextUnlock != null && i.repeat != RepeatRule.none) {
      return Transition(
        i.copyWith(unlockAt: nextUnlock, stage: ItemStages.sealed, status: ItemStatus.active,
            completedAt: null, updatedAt: now, lastReviewedAt: now),
        ItemEvent(itemId: i.id, type: EventType.unlocked, at: now, categoryId: i.categoryId),
      );
    }
    return Transition(
      i.copyWith(stage: ItemStages.opened, status: ItemStatus.done, completedAt: now, updatedAt: now,
          lastReviewedAt: now),
      ItemEvent(itemId: i.id, type: EventType.unlocked, at: now, categoryId: i.categoryId),
    );
  }

  /// Marks an idea/wishlist item as reviewed (restarts its review clock).
  static Transition review(LaterItem i, DateTime now) => Transition(
        i.copyWith(lastReviewedAt: now, lastKeptAt: now, updatedAt: now),
        ItemEvent(itemId: i.id, type: EventType.kept, at: now, categoryId: i.categoryId),
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
        stage: 0,
        completedAt: null,
        droppedAt: null,
        updatedAt: now,
      );
}
