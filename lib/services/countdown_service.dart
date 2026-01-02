enum GameType { lotto, eurojackpot }

class CountdownService {
  static DateTime nextDraw(GameType type, DateTime now) {
    if (type == GameType.lotto) {
      // Lotto 6aus49: Mittwoch 18:25, Samstag 19:25
      return _nextWeekdayTime(
        now,
        weekdays: const [DateTime.wednesday, DateTime.saturday],
        times: const {
          DateTime.wednesday: _Time(18, 25),
          DateTime.saturday: _Time(19, 25),
        },
      );
    } else {
      // Eurojackpot: Dienstag & Freitag 20:00
      return _nextWeekdayTime(
        now,
        weekdays: const [DateTime.tuesday, DateTime.friday],
        times: const {
          DateTime.tuesday: _Time(20, 0),
          DateTime.friday: _Time(20, 0),
        },
      );
    }
  }

  static Duration remaining(GameType type) {
    final now = DateTime.now();
    final next = nextDraw(type, now);
    return next.difference(now);
  }

  static DateTime _nextWeekdayTime(
    DateTime now, {
    required List<int> weekdays,
    required Map<int, _Time> times,
  }) {
    DateTime? candidate;

    for (final weekday in weekdays) {
      final t = times[weekday]!;
      DateTime d = DateTime(
        now.year,
        now.month,
        now.day,
        t.hour,
        t.minute,
      );

      int diff = (weekday - now.weekday) % 7;
      if (diff < 0) diff += 7;
      d = d.add(Duration(days: diff));

      if (d.isBefore(now)) {
        d = d.add(const Duration(days: 7));
      }

      candidate = candidate == null || d.isBefore(candidate) ? d : candidate;
    }

    return candidate!;
  }
}

class _Time {
  final int hour;
  final int minute;
  const _Time(this.hour, this.minute);
}
