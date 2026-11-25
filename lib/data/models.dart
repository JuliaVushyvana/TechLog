import 'dart:math';

String newId() {
  final r = Random();
  return List.generate(10, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[r.nextInt(36)]).join();
}

const directions = ['Roblox', 'Start & Click', 'МА', 'Інше'];

enum LessonStatus {
  planned('заплановано', '—'),
  done('проведено', '✓'),
  cancelled('скасовано', '✗'),
  makeup('відпрацювання', '↻');

  const LessonStatus(this.label, this.mark);
  final String label;
  final String mark;

  bool get counts => this == done || this == makeup;

  static LessonStatus parse(String? s) => values.firstWhere((v) => v.name == s, orElse: () => planned);
}

class Student {
  Student({
    required this.id,
    required this.name,
    this.age,
    List<String>? directions,
    this.level = '',
    this.parentContact = '',
    this.notes = '',
    this.inclusion = false,
    this.archived = false,
  }) : directions = directions ?? ['Roblox'];

  final String id;
  String name;
  int? age;
  List<String> directions;
  String level;
  String parentContact;
  String notes;
  bool inclusion;
  bool archived;

  String get dir => directions.isEmpty ? 'Інше' : directions.first;
  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': name,
    'age': age,
    'directions': directions,
    'level': level,
    'parentContact': parentContact,
    'notes': notes,
    'inclusion': inclusion,
    'archived': archived,
  };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
    id: j['id'],
    name: j['fullName'] ?? '',
    age: j['age'],
    directions: List<String>.from(j['directions'] ?? const []),
    level: j['level'] ?? '',
    parentContact: j['parentContact'] ?? '',
    notes: j['notes'] ?? '',
    inclusion: j['inclusion'] ?? false,
    archived: j['archived'] ?? false,
  );
}

class Lesson {
  Lesson({
    required this.id,
    required this.date,
    required this.time,
    required this.studentId,
    required this.type,
    this.status = LessonStatus.planned,
    this.topic = '',
    this.description = '',
    this.activity,
    this.scheduleId,
    this.origDate,
  });

  final String id;

  /// yyyy-MM-dd
  String date;

  /// HH:mm
  String time;
  String studentId;
  String type;
  LessonStatus status;
  String topic;
  String description;
  int? activity;
  String? scheduleId;
  String? origDate;

  bool get isBlank => topic.isEmpty && description.isEmpty && activity == null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'time': time,
    'studentId': studentId,
    'lessonType': type,
    'status': status.name,
    'topic': topic,
    'description': description,
    'activity': activity,
    'scheduleId': scheduleId,
    'origDate': origDate,
  };

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
    id: j['id'],
    date: j['date'],
    time: j['time'],
    studentId: j['studentId'],
    type: j['lessonType'] ?? '',
    status: LessonStatus.parse(j['status']),
    topic: j['topic'] ?? '',
    description: j['description'] ?? '',
    activity: j['activity'],
    scheduleId: j['scheduleId'],
    origDate: j['origDate'],
  );
}

/// Повторюване заняття: щотижня в [weekday] (0 = Пн) о [time].
class Schedule {
  Schedule({
    required this.id,
    required this.weekday,
    required this.time,
    required this.studentId,
    required this.type,
    required this.from,
  });

  final String id;
  int weekday;
  String time;
  String studentId;
  String type;
  String from;

  Map<String, dynamic> toJson() => {
    'id': id,
    'weekday': weekday,
    'time': time,
    'studentId': studentId,
    'lessonType': type,
    'from': from,
  };

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
    id: j['id'],
    weekday: j['weekday'],
    time: j['time'],
    studentId: j['studentId'],
    type: j['lessonType'] ?? '',
    from: j['from'],
  );
}

class TrainerResult {
  TrainerResult({
    required this.id,
    required this.studentId,
    required this.trainer,
    required this.settings,
    required this.date,
    required this.timeSec,
    this.correct,
    this.total,
  });

  final String id;
  final String studentId;
  final String trainer;
  final Map<String, String> settings;
  final String date;
  final double timeSec;
  final int? correct;
  final int? total;

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'trainer': trainer,
    'settings': settings,
    'date': date,
    'timeSec': timeSec,
    'correct': correct,
    'total': total,
  };

  factory TrainerResult.fromJson(Map<String, dynamic> j) => TrainerResult(
    id: j['id'],
    studentId: j['studentId'],
    trainer: j['trainer'],
    settings: Map<String, String>.from(j['settings'] ?? const {}),
    date: j['date'],
    timeSec: (j['timeSec'] as num).toDouble(),
    correct: j['correct'],
    total: j['total'],
  );
}

class FeedbackDoc {
  FeedbackDoc({required this.studentId, required this.month, required this.text, required this.updated});

  final String studentId;

  /// yyyy-MM
  final String month;
  String text;
  String updated;

  String get key => '$studentId|$month';

  Map<String, dynamic> toJson() => {'studentId': studentId, 'month': month, 'text': text, 'updated': updated};

  factory FeedbackDoc.fromJson(Map<String, dynamic> j) =>
      FeedbackDoc(studentId: j['studentId'], month: j['month'], text: j['text'] ?? '', updated: j['updated'] ?? '');
}

class AiSettings {
  AiSettings({
    this.tone = 'Теплий',
    this.length = 'Середньо',
    this.language = 'Українська',
    this.signature = '',
    this.extra = '',
  });

  String tone;
  String length;
  String language;
  String signature;
  String extra;

  static const tones = {
    'Теплий': 'теплий, підтримуючий, дружній',
    'Діловий': 'стриманий, діловий, конкретний',
    'Натхненний': 'енергійний, мотиваційний, з похвалою',
  };
  static const lengths = {'Коротко': '80–110 слів', 'Середньо': '140–190 слів', 'Детально': '230–300 слів'};
  static const languages = ['Українська', 'English'];

  Map<String, dynamic> toJson() => {
    'tone': tone,
    'length': length,
    'language': language,
    'signature': signature,
    'extra': extra,
  };

  factory AiSettings.fromJson(Map<String, dynamic> j) => AiSettings(
    tone: j['tone'] ?? 'Теплий',
    length: j['length'] ?? 'Середньо',
    language: j['language'] ?? 'Українська',
    signature: j['signature'] ?? '',
    extra: j['extra'] ?? '',
  );
}
