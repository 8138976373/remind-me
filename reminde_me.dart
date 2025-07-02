import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // For jsonDecode/jsonEncode if AIService were enabled
import 'package:http/http.dart' as http; // For AIService if enabled
import 'package:provider/provider.dart';
import 'dart:async'; // Required for Timer and StreamController

// --- Global Constants (Mocked for environment where Firebase is not allowed) ---
// These are not truly global but serve as mock data for the user ID.
// In a real app with authentication, this would come from the auth system.
const String _mockUserId = 'mock_user_123_abc';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReminderProvider>(
      create: (BuildContext context) => ReminderProvider(),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'Beautiful Reminders',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'Inter', // Using Inter font for a modern look
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
            ),
            cardTheme: CardThemeData(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.deepPurple.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          home: const HomeScreen(userId: _mockUserId), // Pass mock user ID
        );
      },
    );
  }
}

// --- Reminder Enums ---
enum ReminderPriority {
  low,
  medium,
  high,
  critical,
}

enum ReminderFilter {
  all,
  today,
  next7Days,
  next30Days,
}

// --- Reminder Model ---
class Reminder {
  final String id;
  String userId; // Keeping userId for data structure consistency
  String title;
  String? description;
  DateTime dateTime;
  bool isCompleted;
  bool isRecurring;
  ReminderPriority priority; // New field
  String? imageUrl; // New field
  final DateTime createdAt;

  Reminder({
    String? id, // Optional for constructor, will be generated if null
    required this.userId,
    required this.title,
    this.description,
    required this.dateTime,
    this.isCompleted = false,
    this.isRecurring = false,
    this.priority = ReminderPriority.medium, // Default priority
    this.imageUrl, // Optional image URL
    DateTime? createdAt, // Optional for constructor
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  // Helper method to create a copy for updates
  Reminder copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isCompleted,
    bool? isRecurring,
    ReminderPriority? priority,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isRecurring: isRecurring ?? this.isRecurring,
      priority: priority ?? this.priority,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// --- State Management: ReminderProvider using ChangeNotifier ---
class ReminderProvider extends ChangeNotifier {
  final List<Reminder> _reminders = <Reminder>[];
  ReminderFilter _currentFilter = ReminderFilter.all;

  late final StreamController<Reminder> _dueReminderStreamController;
  Stream<Reminder> get dueRemindersStream => _dueReminderStreamController.stream;

  Timer? _notificationTimer;
  final Set<String> notifiedReminderIds = <String>{}; // Track notified reminders

  ReminderProvider() {
    _dueReminderStreamController = StreamController<Reminder>.broadcast();
    _initializeDummyData();
    _sortReminders();
    _startNotificationTimer();
  }

  void _initializeDummyData() {
    _reminders.addAll(<Reminder>[
      Reminder(
        userId: _mockUserId,
        title: 'Buy Groceries',
        description: 'Milk, eggs, bread, cheese',
        dateTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
        isCompleted: false,
        isRecurring: false,
        priority: ReminderPriority.high,
        imageUrl:
            'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
      ),
      Reminder(
        userId: _mockUserId,
        title: 'Meeting with John',
        description: 'Discuss Q3 strategy',
        dateTime: DateTime.now().add(const Duration(hours: 2)),
        isCompleted: false,
        isRecurring: false,
        priority: ReminderPriority.critical,
      ),
      Reminder(
        userId: _mockUserId,
        title: 'Pay Bills (Overdue)',
        description: 'Electricity, Water',
        dateTime: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
        isCompleted: false,
        isRecurring: false,
        priority: ReminderPriority.high,
      ),
      Reminder(
        userId: _mockUserId,
        title: 'Submit Expense Report',
        description: null,
        dateTime: DateTime.now().subtract(const Duration(days: 10, hours: 1)),
        isCompleted: true,
        isRecurring: false,
        priority: ReminderPriority.medium,
      ),
      Reminder(
        userId: _mockUserId,
        title: 'Call Insurance Company',
        description: 'Regarding car accident claim',
        dateTime: DateTime.now().add(const Duration(days: 15)),
        isCompleted: false,
        isRecurring: false,
        priority: ReminderPriority.low,
      ),
      Reminder(
        userId: _mockUserId,
        title: 'Plan Birthday Party',
        description: 'Decorations, cake, guest list',
        dateTime: DateTime.now().add(const Duration(days: 25, hours: 18)),
        isCompleted: false,
        isRecurring: false,
        priority: ReminderPriority.medium,
      ),
      // Add dummy reminders for immediate notification testing
      Reminder(
        userId: _mockUserId,
        title: 'Coffee Break Soon!',
        description: 'Time to grab a cup',
        dateTime: DateTime.now().add(const Duration(seconds: 30)),
        isCompleted: false,
        isRecurring: false,
        priority: ReminderPriority.low,
      ),
      Reminder(
        userId: _mockUserId,
        title: 'Daily Standup (Overdue)',
        description: 'Check in with the team',
        dateTime: DateTime.now().subtract(const Duration(minutes: 5)),
        isCompleted: false,
        isRecurring: false,
        priority: ReminderPriority.critical,
      ),
    ]);
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel(); // Cancel any existing timer
    _notificationTimer =
        Timer.periodic(const Duration(seconds: 30), (Timer timer) {
      _checkAndNotifyDueReminders();
    });
    // Run once immediately on start to catch any already overdue reminders
    _checkAndNotifyDueReminders();
  }

  void _checkAndNotifyDueReminders() {
    final DateTime now = DateTime.now();
    // Notify for reminders that are up to 1 minute in the future or already past
    final DateTime futureThreshold = now.add(const Duration(minutes: 1));

    for (final Reminder reminder in _reminders) {
      if (!reminder.isCompleted &&
          !notifiedReminderIds.contains(reminder.id) &&
          (reminder.dateTime.isBefore(now) ||
              reminder.dateTime.isBefore(futureThreshold))) {
        if (!_dueReminderStreamController.isClosed) {
          _dueReminderStreamController.add(reminder);
          notifiedReminderIds.add(reminder.id);
        }
      }
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _dueReminderStreamController.close();
    super.dispose();
  }

  ReminderFilter get currentFilter => _currentFilter;

  void setFilter(ReminderFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  List<Reminder> get reminders {
    _sortReminders(); // Always sort first
    return List<Reminder>.unmodifiable(_filterReminders(_reminders));
  }

  List<Reminder> _filterReminders(List<Reminder> allReminders) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    switch (_currentFilter) {
      case ReminderFilter.all:
        return allReminders;
      case ReminderFilter.today:
        return allReminders
            .where((Reminder r) =>
                r.dateTime.year == today.year &&
                r.dateTime.month == today.month &&
                r.dateTime.day == today.day &&
                !r.isCompleted) // Don't show completed "today" reminders
            .toList();
      case ReminderFilter.next7Days:
        final DateTime sevenDaysFromNow = today.add(const Duration(days: 7));
        return allReminders
            .where((Reminder r) =>
                r.dateTime.isAfter(now) &&
                r.dateTime.isBefore(sevenDaysFromNow) &&
                !r.isCompleted)
            .toList();
      case ReminderFilter.next30Days:
        final DateTime thirtyDaysFromNow = today.add(const Duration(days: 30));
        return allReminders
            .where((Reminder r) =>
                r.dateTime.isAfter(now) &&
                r.dateTime.isBefore(thirtyDaysFromNow) &&
                !r.isCompleted)
            .toList();
    }
  }

  void _sortReminders() {
    _reminders.sort((Reminder a, Reminder b) {
      // Prioritize uncompleted tasks
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;

      // Then by date/time
      return a.dateTime.compareTo(b.dateTime);
    });
  }

  void addReminder(Reminder reminder) {
    _reminders.add(reminder);
    _checkAndNotifyDueReminders(); // Check immediately for new reminders
    notifyListeners();
  }

  void updateReminder(Reminder updatedReminder) {
    final int index =
        _reminders.indexWhere((Reminder r) => r.id == updatedReminder.id);
    if (index != -1) {
      _reminders[index] = updatedReminder;
      // If completed or scheduled for much later, remove from notified list
      if (updatedReminder.isCompleted ||
          updatedReminder.dateTime
              .isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        notifiedReminderIds.remove(updatedReminder.id);
      }
      _checkAndNotifyDueReminders(); // Re-check after update
      notifyListeners();
    }
  }

  void deleteReminder(String reminderId) {
    _reminders.removeWhere((Reminder r) => r.id == reminderId);
    notifiedReminderIds.remove(reminderId);
    notifyListeners();
  }
}

// --- AI Service (Potentially non-functional without a real key) ---
class AIService {
  // This API key is intended to be provided by the Canvas environment.
  // For local testing, replace 'YOUR_GEMINI_API_KEY_HERE' with an actual Gemini API key.
  final String _apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE', // Placeholder for a real key
  );

  Future<Map<String, dynamic>> parseReminderText(String text) async {
    // If the API key is the default placeholder, log an error and return.
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE' || _apiKey.isEmpty) {
      // ignore: avoid_print
      print(
          'AI Service: API key is missing or is a placeholder. AI parsing will not work.');
      return <String, dynamic>{'error': 'AI API key is not configured.'};
    }

    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

    final List<Map<String, dynamic>> chatHistory = <Map<String, dynamic>>[
      <String, dynamic>{
        "role": "user",
        "parts": <Map<String, String>>[
          <String, String>{
            "text":
                "Extract the title, description, date (YYYY-MM-DD), time (HH:MM), and if it's recurring (true/false), and priority (low, medium, high, critical) from the following text. If a field is not present, use null. For date, infer the closest future date if only day/month is provided. For time, infer a reasonable time if not provided (e.g., 09:00). For recurring, assume false if not explicitly stated. For priority, assume 'medium' if not stated. Respond in JSON format according to the schema provided."
          }
        ]
      },
      <String, dynamic>{
        "role": "model",
        "parts": <Map<String, String>>[
          <String, String>{"text": "Understood. Please provide the text."}
        ]
      },
      <String, dynamic>{
        "role": "user",
        "parts": <Map<String, String>>[
          <String, String>{"text": text}
        ]
      }
    ];

    final Map<String, dynamic> payload = <String, dynamic>{
      "contents": chatHistory,
      "generationConfig": <String, dynamic>{
        "responseMimeType": "application/json",
        "responseSchema": <String, dynamic>{
          "type": "OBJECT",
          "properties": <String, dynamic>{
            "title": <String, String>{"type": "STRING"},
            "description": <String, dynamic>{"type": "STRING", "nullable": true},
            "date": <String, String>{"type": "STRING", "format": "date"}, // YYYY-MM-DD
            "time": <String, String>{"type": "STRING", "format": "time"}, // HH:MM
            "isRecurring": <String, String>{"type": "BOOLEAN"},
            "priority": <String, dynamic>{
              "type": "STRING",
              "enum": <String>["low", "medium", "high", "critical"]
            }
          },
          "required": <String>["title", "date", "time", "isRecurring", "priority"]
        }
      }
    };

    try {
      final http.Response response = await http.post(
        Uri.parse('$apiUrl?key=$_apiKey'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result =
            json.decode(response.body) as Map<String, dynamic>;
        if (result['candidates'] != null &&
            (result['candidates'] as List<dynamic>).isNotEmpty &&
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null &&
            (result['candidates'][0]['content']['parts'] as List<dynamic>)
                .isNotEmpty) {
          final String jsonString =
              result['candidates'][0]['content']['parts'][0]['text'] as String;
          return json.decode(jsonString) as Map<String, dynamic>;
        } else {
          // ignore: avoid_print
          print('AI Service: Unexpected response structure: $result');
          return <String, dynamic>{'error': 'Unexpected AI response structure'};
        }
      } else {
        // ignore: avoid_print
        print(
            'AI Service: API call failed with status: ${response.statusCode}, body: ${response.body}');
        return <String, dynamic>{
          'error': 'API call failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      // ignore: avoid_print
      print('AI Service: Error making API call: $e');
      return <String, dynamic>{'error': 'Network or parsing error: $e'};
    }
  }
}

// --- Custom Widgets ---
class ReminderCard extends StatelessWidget {
  final String title;
  final String? description;
  final DateTime dateTime;
  final bool isCompleted;
  final ReminderPriority priority;
  final String? imageUrl;
  final Color accentColor;

  const ReminderCard({
    super.key,
    required this.title,
    this.description,
    required this.dateTime,
    required this.isCompleted,
    required this.priority,
    this.imageUrl,
    required this.accentColor,
  });

  static IconData getPriorityIcon(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Icons.flag;
      case ReminderPriority.medium:
        return Icons.flag;
      case ReminderPriority.high:
        return Icons.warning_amber_rounded;
      case ReminderPriority.critical:
        return Icons.crisis_alert;
    }
  }

  static Color getPriorityColor(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Colors.blue.shade300;
      case ReminderPriority.medium:
        return Colors.orange.shade300;
      case ReminderPriority.high:
        return Colors.red.shade400;
      case ReminderPriority.critical:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
            color: isCompleted ? Colors.green.shade400 : accentColor,
            width: 2), // Dynamic border accent
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  ReminderCard.getPriorityIcon(priority),
                  color: ReminderCard.getPriorityColor(priority),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isCompleted ? Colors.grey : Colors.deepPurple,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : Colors.grey,
                  size: 24,
                ),
              ],
            ),
            if (description != null && description!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isCompleted ? Colors.grey.shade600 : Colors.grey.shade800,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(Icons.calendar_today,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(dateTime),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  DateFormat('h:mm a').format(dateTime),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            if (imageUrl != null && imageUrl!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object error,
                      StackTrace? stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.grey.shade400),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Screens ---

// Home Screen
class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<Reminder>? _reminderNotificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToReminderNotifications();
    });
  }

  void _subscribeToReminderNotifications() {
    final ReminderProvider reminderProvider = context.read<ReminderProvider>();
    _reminderNotificationSubscription =
        reminderProvider.dueRemindersStream.listen((Reminder reminder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 Reminder: ${reminder.title} is due!'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => AddEditReminderScreen(
                    userId: widget.userId,
                    reminder: reminder,
                  ),
                ),
              );
            },
          ),
          duration: const Duration(seconds: 10), // Keep longer for notice
        ),
      );
    });
  }

  @override
  void dispose() {
    _reminderNotificationSubscription?.cancel();
    super.dispose();
  }

  Color _getReminderAccentColor(DateTime reminderTime, bool isCompleted) {
    if (isCompleted) {
      return Colors.green.shade400; // Completed reminders are green
    }
    final DateTime now = DateTime.now();
    if (reminderTime.isBefore(now)) {
      return Colors.red.shade400; // Overdue reminders are red
    }
    // Upcoming reminders have varying shades of purple/blue
    final int difference = reminderTime.difference(now).inDays;
    if (difference <= 1) {
      return Colors.deepPurpleAccent.shade400; // Within 1 day
    } else if (difference <= 7) {
      return Colors.deepPurple.shade300; // Within 1 week
    } else {
      return Colors.indigo.shade200; // More than a week away
    }
  }

  @override
  Widget build(BuildContext context) {
    final ReminderProvider reminderProvider = context.watch<ReminderProvider>();
    final List<Reminder> reminders = reminderProvider.reminders;
    final ReminderFilter currentFilter = reminderProvider.currentFilter;

    final TextStyle defaultLabelStyle = (Theme.of(context).textTheme.labelSmall ??
            const TextStyle(fontSize: 12, color: Colors.black))
        as TextStyle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reminders'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'User ID: ${widget.userId}', // Display the mock user ID
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<ReminderFilter>(
              segments: <ButtonSegment<ReminderFilter>>[
                ButtonSegment<ReminderFilter>(
                  value: ReminderFilter.all,
                  label: Text('All', style: defaultLabelStyle),
                  icon: const Icon(Icons.list),
                ),
                ButtonSegment<ReminderFilter>(
                  value: ReminderFilter.today,
                  label: Text('Today', style: defaultLabelStyle),
                  icon: const Icon(Icons.today),
                ),
                ButtonSegment<ReminderFilter>(
                  value: ReminderFilter.next7Days,
                  label: Text('Next 7 Days', style: defaultLabelStyle),
                  icon: const Icon(Icons.calendar_view_week),
                ),
                ButtonSegment<ReminderFilter>(
                  value: ReminderFilter.next30Days,
                  label: Text('Next 30 Days', style: defaultLabelStyle),
                  icon: const Icon(Icons.calendar_month),
                ),
              ],
              selected: <ReminderFilter>{currentFilter},
              onSelectionChanged: (Set<ReminderFilter> newSelection) {
                if (newSelection.isNotEmpty) {
                  context
                      .read<ReminderProvider>()
                      .setFilter(newSelection.first);
                }
              },
              multiSelectionEnabled: false,
              emptySelectionAllowed: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Theme.of(context).primaryColor,
                selectedForegroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Expanded(
            child: reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No reminders for this filter!',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Try a different filter or add a new reminder.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: reminders.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Reminder reminder = reminders[index];
                      return Dismissible(
                        key: ValueKey<String>(
                            reminder.id), // Unique key for Dismissible
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (DismissDirection direction) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Confirm Delete"),
                                    content: const Text(
                                        "Are you sure you want to delete this reminder?"),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              ) ??
                              false;
                        },
                        onDismissed: (DismissDirection direction) {
                          context
                              .read<ReminderProvider>()
                              .deleteReminder(reminder.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${reminder.title} dismissed')),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) =>
                                    AddEditReminderScreen(
                                  userId: widget.userId,
                                  reminder:
                                      reminder, // Pass existing reminder for editing
                                ),
                              ),
                            );
                          },
                          child: ReminderCard(
                            title: reminder.title,
                            description: reminder.description,
                            dateTime: reminder.dateTime,
                            isCompleted: reminder.isCompleted,
                            priority: reminder.priority,
                            imageUrl: reminder.imageUrl,
                            accentColor: _getReminderAccentColor(
                                reminder.dateTime, reminder.isCompleted),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  AddEditReminderScreen(userId: widget.userId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Add/Edit Reminder Screen
class AddEditReminderScreen extends StatefulWidget {
  final String userId;
  final Reminder? reminder; // Null for adding, non-null for editing

  const AddEditReminderScreen({super.key, required this.userId, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AIService _aiService = AIService(); // AI service instance

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _aiInputController; // For AI text input
  late TextEditingController _imageUrlController; // For image URL input
  late DateTime _selectedDateTime;
  late bool _isCompleted;
  late bool _isRecurring;
  late ReminderPriority _selectedPriority; // New state variable for priority
  bool _isParsingAI = false; // To show loading for AI

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _aiInputController = TextEditingController();
    _imageUrlController = TextEditingController();

    if (widget.reminder != null) {
      // Editing an existing reminder
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description ?? '';
      _selectedDateTime = widget.reminder!.dateTime;
      _isCompleted = widget.reminder!.isCompleted;
      _isRecurring = widget.reminder!.isRecurring;
      _selectedPriority = widget.reminder!.priority;
      _imageUrlController.text = widget.reminder!.imageUrl ?? '';
    } else {
      // Adding a new reminder, set default time to next hour
      _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        _selectedDateTime.hour,
        0, // Round to the nearest hour
      );
      _isCompleted = false;
      _isRecurring = false;
      _selectedPriority = ReminderPriority.medium; // Default for new
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _aiInputController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDateTime) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _parseWithAI() async {
    if (_aiInputController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text for AI parsing.')),
      );
      return;
    }

    setState(() {
      _isParsingAI = true;
    });

    try {
      final Map<String, dynamic> parsedData =
          await _aiService.parseReminderText(_aiInputController.text);

      if (parsedData.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Error: ${parsedData['error']}')),
        );
        return;
      }

      setState(() {
        _titleController.text =
            (parsedData['title'] as String?) ?? _titleController.text;
        _descriptionController.text =
            (parsedData['description'] as String?) ?? _descriptionController.text;
        _isRecurring = (parsedData['isRecurring'] as bool?) ?? false;
        _selectedPriority = ReminderPriority.values.firstWhere(
          (ReminderPriority e) =>
              e.name == (parsedData['priority'] as String).toLowerCase(),
          orElse: () => ReminderPriority.medium,
        );

        // Parse date and time
        try {
          final String dateString = parsedData['date'] as String;
          final String timeString = parsedData['time'] as String;
          final DateTime parsedDate =
              DateFormat('yyyy-MM-dd').parse(dateString);
          final TimeOfDay parsedTime = TimeOfDay(
            hour: int.parse(timeString.split(':')[0]),
            minute: int.parse(timeString.split(':')[1]),
          );

          _selectedDateTime = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedTime.hour,
            parsedTime.minute,
          );
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing date/time from AI: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'AI could not parse date/time accurately. Please set manually.')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to parse with AI: $e')),
      );
    } finally {
      setState(() {
        _isParsingAI = false;
      });
    }
  }

  void _saveReminder() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final Reminder newReminder = Reminder(
        id: widget.reminder?.id, // Keep ID if editing, generate if null
        userId: widget.userId,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        dateTime: _selectedDateTime,
        isCompleted: _isCompleted,
        isRecurring: _isRecurring,
        priority: _selectedPriority,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        createdAt:
            widget.reminder?.createdAt, // Keep original creation date if editing
      );

      if (widget.reminder == null) {
        // Adding new reminder
        context.read<ReminderProvider>().addReminder(newReminder);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder added!')),
        );
      } else {
        // Updating existing reminder
        context.read<ReminderProvider>().updateReminder(newReminder);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder updated!')),
        );
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.reminder == null ? 'Add New Reminder' : 'Edit Reminder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Call Mom, Buy Groceries',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Discuss weekend plans, Milk, eggs, bread',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // AI Input Section
              Text(
                'AI Reminder Creation (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _aiInputController,
                      decoration: const InputDecoration(
                        labelText: 'Describe your reminder',
                        hintText:
                            'e.g., "Meeting tomorrow at 10 AM with John, high priority"',
                        prefixIcon: Icon(Icons.smart_toy),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Align button
                    child: _isParsingAI
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _parseWithAI,
                            child: const Text('Parse with AI'),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Date and Time Pickers
              Row(
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_selectedDateTime),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          DateFormat('h:mm a').format(_selectedDateTime),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Priority Dropdown
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.flag),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReminderPriority>(
                    value: _selectedPriority,
                    isExpanded: true,
                    onChanged: (ReminderPriority? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPriority = newValue;
                        });
                      }
                    },
                    items: ReminderPriority.values
                        .map<DropdownMenuItem<ReminderPriority>>(
                            (ReminderPriority priority) {
                      return DropdownMenuItem<ReminderPriority>(
                        value: priority,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              ReminderCard.getPriorityIcon(priority),
                              color: ReminderCard.getPriorityColor(priority),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              priority.name.toUpperCase(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Image URL input
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  hintText: 'e.g., https://example.com/image.jpg',
                  prefixIcon: Icon(Icons.image),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              // Is Completed & Is Recurring Switches
              SwitchListTile(
                title: const Text('Mark as Completed'),
                value: _isCompleted,
                onChanged: (bool newValue) {
                  setState(() {
                    _isCompleted = newValue;
                  });
                },
                secondary: const Icon(Icons.check_circle_outline),
                activeColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Recurring Reminder'),
                value: _isRecurring,
                onChanged: (bool newValue) {
                  setState(() {
                    _isRecurring = newValue;
                  });
                },
                secondary: const Icon(Icons.repeat),
                activeColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _saveReminder,
                  child: Text(widget.reminder == null
                      ? 'Add Reminder'
                      : 'Update Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
