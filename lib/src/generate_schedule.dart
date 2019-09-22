import 'services/state_serialization.dart';

class ScheduleGenerator {
  final StateSerializationService _serializer;
  ScheduleGenerator(this._serializer);

  Future<List<List<Object>>> generateSchedule(
      Set<String> availablePeriods) async {
    //List<List<Object>> ret = [];
    List<StructuredSchedule> out = [];
    var schedules = await _serializer.loadSchedulesForSignups();
    Set<int> remainingSignups = schedules.keys.toSet();
    var periodFrequencies = {for (var period in availablePeriods) period: 0};

    Future<void> scheduleClassesForPriority(int priority) async {
      Map<int, Set<StructuredSchedule>> schedulesWith = {};

      // find all needed schedules with the given priority
      for (var id in remainingSignups) {
        for (var schedule in schedules[id]) {
          if (availablePeriods.contains(schedule.period) &&
              await priorityFor(schedule.clazz) == priority) {
            schedulesWith[id]?.add(schedule) ??
                (schedulesWith[id] = {schedule});
          }
        }
      }

      // add all schedules for students that only have one
      Set<Set<StructuredSchedule>> remainingSchedules = {};
      for (var entry in schedulesWith.entries) {
        if (entry.value.length == 1) {
          out.add(entry.value.single);
          periodFrequencies[entry.value.single.period]++;
          remainingSignups.remove(entry.key);
        } else {
          remainingSchedules.add(entry.value);
        }
      }

      // iterate over remaining, adding to least populated period
      for (var scheduleSet in remainingSchedules) {
        StructuredSchedule schedule = scheduleSet.fold(
            null,
            (a, b) => a == null
                ? b
                : periodFrequencies[a.period] < periodFrequencies[b.period]
                    ? a
                    : b);
        out.add(schedule);
        periodFrequencies[schedule.period]++;
        remainingSignups.remove(schedule.id);
      }
    }

    await scheduleClassesForPriority(1);
    await scheduleClassesForPriority(2);
    await scheduleClassesForPriority(3);

    out.sort((a, b) {
      var ret = a.period.compareTo(b.period);
      if (ret != 0) return ret;
      ret = a.clazz.compareTo(b.clazz);
      if (ret != 0) return ret;
      return a.id - b.id;
    });

    return out.map((s) => s.rawCsv).toList();
  }

  final Map<String, int> _priorityCache = {};
  Future<int> priorityFor(String clazz) async {
    if (_priorityCache.containsKey(clazz)) {
      return _priorityCache[clazz];
    } else {
      return _priorityCache[clazz] =
          await _serializer.getPriorityForClass(clazz, defaultPriority: -1);
    }
  }
}
