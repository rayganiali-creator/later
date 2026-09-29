import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/util/dates.dart';
import 'package:later/core/util/text.dart';
import 'package:later/domain/models.dart';
import 'package:later/domain/reminders.dart';
import 'package:later/domain/search_filter_sort.dart';
import 'package:later/domain/smart_pick.dart';
import 'package:later/domain/snooze.dart';

import 'helpers.dart';

void main() {
  // t0 = Wednesday 2026-09-30 10:00
  group('Dates', () {
    test('startOfWeek honours week start', () {
      expect(Dates.startOfWeek(t0, DateTime.saturday), DateTime(2026, 9, 26));
      expect(Dates.startOfWeek(t0, DateTime.monday), DateTime(2026, 9, 28));
      expect(Dates.startOfWeek(DateTime(2026, 9, 26, 23), DateTime.saturday),
          DateTime(2026, 9, 26));
    });

    test('daysBetween ignores time and DST', () {
      expect(Dates.daysBetween(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 22, 1)), 2);
      expect(Dates.daysBetween(DateTime(2026, 10, 1), DateTime(2026, 9, 29)), -2);
    });

    test('addMonths clamps end of month (gregorian)', () {
      expect(Dates.addMonths(DateTime(2026, 1, 31), 1, CalendarSystem.gregorian),
          DateTime(2026, 2, 28));
      expect(Dates.addMonths(DateTime(2026, 12, 15), 1, CalendarSystem.gregorian),
          DateTime(2027, 1, 15));
    });

    test('addMonths jalali', () {
      // 1405/07/08 (2026-09-30) + 1 month = 1405/08/08 = 2026-10-30
      final d = Dates.addMonths(t0, 1, CalendarSystem.jalali);
      final p = Dates.parts(d, CalendarSystem.jalali);
      expect((p.year, p.month, p.day), (1405, 8, 8));
    });

    test('jalali formatting', () {
      expect(
          Dates.formatDate(t0, CalendarSystem.jalali, fa: true),
          '${toFaDigits(8)} مهر ${toFaDigits(1405)}');
      expect(Dates.formatDate(t0, CalendarSystem.gregorian, fa: false), '30 Sep 2026');
      expect(
          Dates.formatDate(t0, CalendarSystem.jalali,
              fa: true, now: t0, omitCurrentYear: true),
          '${toFaDigits(8)} مهر');
    });

    test('parts/fromParts round trip', () {
      for (final cal in CalendarSystem.values) {
        final p = Dates.parts(t0, cal);
        expect(Dates.fromParts(p.year, p.month, p.day, cal), Dates.startOfDay(t0));
      }
    });
  });

  group('Snooze', () {
    const calc = SnoozeCalculator(
      weekStart: DateTime.saturday,
      weekendDay: DateTime.friday,
      calendar: CalendarSystem.gregorian,
    );

    test('tonight / tomorrow / weekend / next week / next month / none', () {
      expect(calc.compute(SnoozeOption.tonight, t0).dueAt, DateTime(2026, 9, 30, 20));
      expect(calc.compute(SnoozeOption.tonight, t0).hasTime, isTrue);
      expect(calc.compute(SnoozeOption.tomorrow, t0).dueAt, DateTime(2026, 10, 1));
      expect(calc.compute(SnoozeOption.weekend, t0).dueAt, DateTime(2026, 10, 2)); // Friday
      expect(calc.compute(SnoozeOption.nextWeek, t0).dueAt, DateTime(2026, 10, 3)); // Saturday
      expect(calc.compute(SnoozeOption.nextMonth, t0).dueAt, DateTime(2026, 10, 30));
      expect(calc.compute(SnoozeOption.noDate, t0).dueAt, isNull);
    });

    test('weekend on a Friday goes to next Friday', () {
      final fri = DateTime(2026, 10, 2, 9);
      expect(calc.compute(SnoozeOption.weekend, fri).dueAt, DateTime(2026, 10, 9));
    });

    test('tonight late in the evening never lands in the past', () {
      final late = DateTime(2026, 9, 30, 21, 30);
      final r = calc.compute(SnoozeOption.tonight, late).dueAt!;
      expect(r.isAfter(late), isTrue);
      final veryLate = DateTime(2026, 9, 30, 23, 30);
      final r2 = calc.compute(SnoozeOption.tonight, veryLate).dueAt!;
      expect(r2, DateTime(2026, 10, 1, 20));
    });
  });

  group('Filtering', () {
    final today = item('today', due: DateTime(2026, 9, 30));
    final weekLater = item('week', due: DateTime(2026, 10, 2)); // Fri, same week (Sat start)
    final nextWeek = item('nw', due: DateTime(2026, 10, 5));
    final none = item('none');
    final overdue = item('over', due: DateTime(2026, 9, 20));
    final overdueTime = item('overt', due: DateTime(2026, 9, 30, 9), hasTime: true);
    final laterToday = item('lt', due: DateTime(2026, 9, 30, 18), hasTime: true);
    final high = item('high', priority: Priority.high);
    final all = [today, weekLater, nextWeek, none, overdue, overdueTime, laterToday, high];

    List<String> f(ItemFilter x) => all
        .where((i) => matchesFilter(i, x, t0,
            weekStart: DateTime.saturday, staleDays: 30))
        .map((i) => i.id)
        .toList();

    test('today', () => expect(f(const ItemFilter(FilterKind.today)),
        ['today', 'overt', 'lt']));
    test('this week', () => expect(f(const ItemFilter(FilterKind.thisWeek)),
        ['today', 'week', 'overt', 'lt']));
    test('no date', () => expect(f(const ItemFilter(FilterKind.noDate)), ['none', 'high']));
    test('overdue (date-only overdue after the day, timed after the time)',
        () => expect(f(const ItemFilter(FilterKind.overdue)), ['over', 'overt']));
    test('high priority', () => expect(f(const ItemFilter(FilterKind.highPriority)), ['high']));
    test('all', () => expect(f(ItemFilter.all).length, all.length));
    test('category', () {
      final a = item('a', category: 'read');
      expect(matchesFilter(a, const ItemFilter(FilterKind.category, 'read'), t0,
          weekStart: 1, staleDays: 30), isTrue);
      expect(matchesFilter(a, const ItemFilter(FilterKind.category, 'buy'), t0,
          weekStart: 1, staleDays: 30), isFalse);
    });

    test('recurring items use their next occurrence', () {
      final daily = item('d', due: DateTime(2026, 9, 1), repeat: RepeatRule.daily);
      expect(isDueToday(daily, t0), isTrue);
      expect(isOverdue(daily, t0), isFalse);
      final weekly = item('w', due: DateTime(2026, 9, 16), repeat: RepeatRule.weekly); // Wed
      expect(isDueToday(weekly, t0), isTrue);
      final monthly = item('m', due: DateTime(2026, 8, 15), repeat: RepeatRule.monthly);
      expect(effectiveDue(monthly, t0), DateTime(2026, 10, 15));
    });
  });

  group('Stale', () {
    test('30 days without a plan is stale; kept resets; future plan is not stale', () {
      final old = item('o', created: t0.subtract(const Duration(days: 31)));
      expect(isStale(old, t0, 30), isTrue);
      final kept = item('k',
          created: t0.subtract(const Duration(days: 90)),
          kept: t0.subtract(const Duration(days: 2)));
      expect(isStale(kept, t0, 30), isFalse);
      final planned = item('p',
          created: t0.subtract(const Duration(days: 90)),
          due: t0.add(const Duration(days: 3)));
      expect(isStale(planned, t0, 30), isFalse);
      final done = item('d',
          created: t0.subtract(const Duration(days: 90)), status: ItemStatus.done);
      expect(isStale(done, t0, 30), isFalse);
      final exactly = item('e', created: t0.subtract(const Duration(days: 30)));
      expect(isStale(exactly, t0, 30), isTrue);
      final almost = item('a', created: t0.subtract(const Duration(days: 29)));
      expect(isStale(almost, t0, 30), isFalse);
    });
  });

  group('Search', () {
    final a = item('a',
        title: 'مقاله «ي» را بخوانم',
        description: 'درباره بازي',
        tags: ['کتاب'],
        url: 'https://example.com/post',
        note: 'یادداشت محرمانه',
        category: 'read');
    test('basic: title & description, Arabic/Persian variants and digits', () {
      expect(matchesSearch(a, SearchQuery('مقاله')), isTrue);
      expect(matchesSearch(a, SearchQuery('بازی')), isTrue);
      expect(matchesSearch(a, SearchQuery('مقاله بخوانم')), isTrue);
      expect(matchesSearch(a, SearchQuery('مقاله سینما')), isFalse);
      expect(matchesSearch(a, SearchQuery('')), isTrue);
      expect(matchesSearch(item('n', title: 'قرار ۱۲ صبح'), SearchQuery('12')), isTrue);
    });
    test('basic search does not look at tags/url/note', () {
      expect(matchesSearch(a, SearchQuery('کتاب')), isFalse);
      expect(matchesSearch(a, SearchQuery('example')), isFalse);
      expect(matchesSearch(a, SearchQuery('محرمانه')), isFalse);
    });
    test('advanced search covers tags, url, note, category', () {
      bool m(String q) => matchesSearch(a, SearchQuery(q, advanced: true),
          categoryName: (id) => id == 'read' ? 'خواندنی' : id);
      expect(m('کتاب'), isTrue);
      expect(m('#کتاب'), isTrue);
      expect(m('example.com'), isTrue);
      expect(m('محرمانه'), isTrue);
      expect(m('خواندنی'), isTrue);
      expect(m('چیز دیگر'), isFalse);
    });
  });

  group('Sorting', () {
    final a = item('a', created: DateTime(2026, 9, 1), due: DateTime(2026, 10, 5), priority: Priority.low, minutes: 30);
    final b = item('b', created: DateTime(2026, 9, 3), due: DateTime(2026, 10, 1), priority: Priority.high, minutes: 5);
    final c = item('c', created: DateTime(2026, 9, 2), priority: Priority.normal);
    final d = item('d', created: DateTime(2026, 8, 1), due: DateTime(2026, 10, 3), minutes: 120);
    List<String> s(SortMode m) => sortItems([a, b, c, d], m, now: t0).map((e) => e.id).toList();
    test('newest', () => expect(s(SortMode.newest), ['b', 'c', 'a', 'd']));
    test('oldest', () => expect(s(SortMode.oldest), ['d', 'a', 'c', 'b']));
    test('deadline (no date last)', () => expect(s(SortMode.nearestDeadline), ['b', 'd', 'a', 'c']));
    test('priority order', () {
      final r = sortItems([a, b, c, d], SortMode.priority);
      expect(r.first.id, 'b');
      expect(r.last.id, 'a');
    });
    test('shortest (unknown last)', () => expect(s(SortMode.shortest), ['b', 'a', 'd', 'c']));
    test('longest (unknown last)', () => expect(s(SortMode.longest), ['d', 'a', 'b', 'c']));
  });

  group('Smart pick', () {
    final items = [
      item('quick', minutes: 5, created: t0.subtract(const Duration(days: 5))),
      item('med', minutes: 30, created: t0.subtract(const Duration(days: 5))),
      item('long', minutes: 120, created: t0.subtract(const Duration(days: 5))),
      item('unk', created: t0.subtract(const Duration(days: 5))),
      item('done', status: ItemStatus.done, minutes: 5),
    ];

    test('never returns items that do not fit the time window', () {
      final p = SmartPicker(random: Random(1));
      for (var seed = 0; seed < 50; seed++) {
        final r = SmartPicker(random: Random(seed))
            .pick(items, t0, const PickOptions(availableMinutes: 15, limit: 10));
        final ids = r.map((e) => e.item.id).toSet();
        expect(ids.contains('med'), isFalse);
        expect(ids.contains('long'), isFalse);
        expect(ids.contains('done'), isFalse);
      }
      expect(p.pick(items, t0, const PickOptions(availableMinutes: 5, limit: 10)).map((e) => e.item.id),
          contains('quick'));
    });

    test('due today beats undated', () {
      final list = [
        item('undated', created: t0.subtract(const Duration(days: 3))),
        item('today', due: DateTime(2026, 9, 30), created: t0.subtract(const Duration(days: 3))),
      ];
      for (var seed = 0; seed < 30; seed++) {
        final r = SmartPicker(random: Random(seed)).pick(list, t0, const PickOptions());
        expect(r.single.item.id, 'today');
      }
    });

    test('excluded ids are skipped ("give me another")', () {
      final r = SmartPicker(random: Random(3))
          .pick(items, t0, const PickOptions(limit: 10, excludeIds: {'quick', 'med'}));
      expect(r.map((e) => e.item.id), isNot(contains('quick')));
      expect(r.map((e) => e.item.id), isNot(contains('med')));
    });

    test('advanced: priority & category filter', () {
      final list = [
        item('lowp', priority: Priority.low, category: 'read'),
        item('highp', priority: Priority.high, category: 'buy'),
      ];
      final adv = SmartPicker(random: Random(1))
          .pick(list, t0, const PickOptions(advanced: true, limit: 2));
      expect(adv.first.item.id, 'highp');
      final cat = SmartPicker(random: Random(1)).pick(
          list, t0, const PickOptions(advanced: true, categoryId: 'read'));
      expect(cat.single.item.id, 'lowp');
      // basic ignores the category filter (Pro only)
      final basic = SmartPicker(random: Random(1)).pick(
          list, t0, const PickOptions(categoryId: 'read', limit: 5));
      expect(basic.length, 2);
    });

    test('empty list => nothing', () {
      expect(SmartPicker().pick(const [], t0, const PickOptions()), isEmpty);
    });
  });

  group('ReminderPlanner', () {
    const planner = ReminderPlanner();
    List<PlannedReminder> plan(List<LaterItem> l, {bool repeat = true, int max = 100, DateTime? now}) =>
        planner.plan(l, now ?? t0,
            defaultMinutesOfDay: 9 * 60,
            allowRepeat: repeat,
            max: max,
            titleOf: (i) => i.title,
            bodyOf: (i) => '');

    test('timed reminder with offset', () {
      final i = item('a', due: DateTime(2026, 10, 1, 15), hasTime: true, reminder: true, offset: 60);
      expect(plan([i]).single.fireAt, DateTime(2026, 10, 1, 14));
    });
    test('date-only reminder uses default time', () {
      final i = item('a', due: DateTime(2026, 10, 1), reminder: true);
      expect(plan([i]).single.fireAt, DateTime(2026, 10, 1, 9));
    });
    test('past one-time, disabled, undated and done items are not scheduled', () {
      expect(plan([
        item('past', due: DateTime(2026, 9, 1), reminder: true),
        item('off', due: DateTime(2026, 10, 1)),
        item('nodate', reminder: true),
        item('done', due: DateTime(2026, 10, 1), reminder: true, status: ItemStatus.done),
      ]), isEmpty);
    });
    test('repeating reminders roll forward', () {
      final d = item('d', due: DateTime(2026, 9, 1), reminder: true, repeat: RepeatRule.daily);
      expect(plan([d]).single.fireAt, DateTime(2026, 10, 1, 9)); // 09:00 today passed at 10:00
      final w = item('w', due: DateTime(2026, 9, 2), reminder: true, repeat: RepeatRule.weekly);
      expect(plan([w]).single.fireAt, DateTime(2026, 10, 7, 9)); // Wed 09-30 09:00 passed
      final m = item('m', due: DateTime(2026, 8, 31), reminder: true, repeat: RepeatRule.monthly);
      expect(plan([m]).single.fireAt.isAfter(t0), isTrue);
    });
    test('repeat is ignored when not allowed (Pro expired)', () {
      final d = item('d', due: DateTime(2026, 9, 1), reminder: true, repeat: RepeatRule.daily);
      expect(plan([d], repeat: false), isEmpty);
      final f = item('f', due: DateTime(2026, 10, 3), reminder: true, repeat: RepeatRule.daily);
      expect(plan([f], repeat: false).single.repeat, RepeatRule.none);
    });
    test('unique stable ids, sorted, capped', () {
      final l = [for (var k = 0; k < 20; k++) item('id$k', due: DateTime(2026, 10, 1 + (k % 5)), reminder: true)];
      final p = plan(l, max: 7);
      expect(p.length, 7);
      expect(p.map((e) => e.notificationId).toSet().length, 7);
      for (var k = 1; k < p.length; k++) {
        expect(p[k].fireAt.isBefore(p[k - 1].fireAt), isFalse);
      }
      expect(plan(l, max: 7).map((e) => e.notificationId), p.map((e) => e.notificationId));
    });
  });

  group('Text helpers', () {
    test('url sanitizing rejects dangerous schemes', () {
      expect(sanitizeUrl('javascript:alert(1)'), isNull);
      expect(sanitizeUrl('file:///etc/passwd'), isNull);
      expect(sanitizeUrl('intent://x#Intent;end'), isNull);
      expect(sanitizeUrl('content://a/b'), isNull);
      expect(sanitizeUrl('example.com/a'), 'https://example.com/a');
      expect(sanitizeUrl('http://a.b/c?d=1'), 'http://a.b/c?d=1');
      expect(sanitizeUrl('not a url'), isNull);
      expect(sanitizeUrl('  '), isNull);
    });
    test('extractFirstUrl', () {
      expect(extractFirstUrl('ببین: https://a.com/x?y=1, جالبه'), 'https://a.com/x?y=1');
      expect(extractFirstUrl('بدون لینک'), isNull);
    });
    test('digits', () {
      expect(toFaDigits(1405), '۱۴۰۵');
      expect(toEnDigits('۱۲٣'), '123');
    });
  });
}
