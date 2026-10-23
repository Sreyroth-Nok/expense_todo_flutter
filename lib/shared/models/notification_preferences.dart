/// Which kinds of pop-up notifications the user wants.
///
/// Stored in the profile as `notificationPreferences` (a map of bools).
/// Turning a kind off stops device notifications only — the information is
/// still shown inside the app.
class NotificationPreferences {
  const NotificationPreferences({
    this.spendingLimits = true,
    this.reminders = true,
    this.tasks = true,
    this.events = true,
    this.savings = true,
  });

  final bool spendingLimits;
  final bool reminders;
  final bool tasks;
  final bool events;
  final bool savings;

  static const keys = ['spendingLimits', 'reminders', 'tasks', 'events', 'savings'];

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    bool read(String key) => map?[key] as bool? ?? true;
    return NotificationPreferences(
      spendingLimits: read('spendingLimits'),
      reminders: read('reminders'),
      tasks: read('tasks'),
      events: read('events'),
      savings: read('savings'),
    );
  }

  Map<String, bool> toMap() => {
        'spendingLimits': spendingLimits,
        'reminders': reminders,
        'tasks': tasks,
        'events': events,
        'savings': savings,
      };

  NotificationPreferences copyWith({
    bool? spendingLimits,
    bool? reminders,
    bool? tasks,
    bool? events,
    bool? savings,
  }) =>
      NotificationPreferences(
        spendingLimits: spendingLimits ?? this.spendingLimits,
        reminders: reminders ?? this.reminders,
        tasks: tasks ?? this.tasks,
        events: events ?? this.events,
        savings: savings ?? this.savings,
      );
}
