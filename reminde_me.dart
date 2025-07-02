import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // For jsonDecode/jsonEncode if AIService were enabled
import 'package:http/http.dart' as http; // For AIService if enabled
import 'package:provider/provider.dart';

// --- Global Constants (Mocked for environment where Firebase is not allowed) ---
// These are not truly global but serve as mock data for the user ID.
// In a real app with authentication, this would come from the auth system.
const String _mockUserId = 'mock_user_123_abc';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReminderProvider>(
      create: (context) => ReminderProvider(),
      builder: (context, child) {
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
            cardTheme: CardThemeData( // Corrected from CardTheme to CardThemeData
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
          ),
          home: const HomeScreen(userId: _mockUserId), // Pass mock user ID
        );
      },
    );
  }
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
  final DateTime createdAt;

  Reminder({
    String? id, // Optional for constructor, will be generated if null
    required this.userId,
    required this.title,
    this.description,
    required this.dateTime,
    this.isCompleted = false,
    this.isRecurring = false,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// --- State Management: ReminderProvider using ChangeNotifier ---
class ReminderProvider extends ChangeNotifier {
  final List<Reminder> _reminders = [];

  // Initialize with some dummy data
  ReminderProvider() {
    _reminders.add(
      Reminder(
        userId: _mockUserId,
        title: 'Buy Groceries',
        description: 'Milk, eggs, bread, cheese',
        dateTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
        isCompleted: false,
        isRecurring: false,
      ),
    );
    _reminders.add(
      Reminder(
        userId: _mockUserId,
        title: 'Meeting with John',
        description: 'Discuss Q3 strategy',
        dateTime: DateTime.now().add(const Duration(days: 2, hours: 14)),
        isCompleted: false,
        isRecurring: false,
      ),
    );
    _reminders.add(
      Reminder(
        userId: _mockUserId,
        title: 'Pay Bills (Overdue)',
        description: 'Electricity, Water',
        dateTime: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
        isCompleted: false,
        isRecurring: false,
      ),
    );
    _reminders.add(
      Reminder(
        userId: _mockUserId,
        title: 'Submit Expense Report',
        description: null,
        dateTime: DateTime.now().subtract(const Duration(days: 10, hours: 1)),
        isCompleted: true,
        isRecurring: false,
      ),
    );
    _sortReminders();
  }

  // Getter for reminders, sorted by date/time
  List<Reminder> get reminders {
    _sortReminders();
    return List.unmodifiable(_reminders);
  }

  void _sortReminders() {
    _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  void addReminder(Reminder reminder) {
    _reminders.add(reminder);
    notifyListeners();
  }

  void updateReminder(Reminder updatedReminder) {
    final int index = _reminders.indexWhere((Reminder r) => r.id == updatedReminder.id);
    if (index != -1) {
      _reminders[index] = updatedReminder;
      notifyListeners();
    }
  }

  void deleteReminder(String reminderId) {
    _reminders.removeWhere((Reminder r) => r.id == reminderId);
    notifyListeners();
  }
}

// --- AI Service (Potentially non-functional without a real key) ---
// Kept for structural completeness if intended to be used with a real key
// as per environment variable pattern.
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
      print('AI Service: API key is missing or is a placeholder. AI parsing will not work.');
      return <String, dynamic>{'error': 'AI API key is not configured.'};
    }

    const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

    final List<Map<String, dynamic>> chatHistory = <Map<String, dynamic>>[
      <String, dynamic>{
        "role": "user",
        "parts": <Map<String, String>>[
          <String, String>{
            "text":
                "Extract the title, description, date (YYYY-MM-DD), time (HH:MM), and if it's recurring (true/false) from the following text. If a field is not present, use null. For date, infer the closest future date if only day/month is provided. For time, infer a reasonable time if not provided (e.g., 09:00). For recurring, assume false if not explicitly stated. Respond in JSON format according to the schema provided."
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
            "isRecurring": <String, String>{"type": "BOOLEAN"}
          },
          "required": <String>["title", "date", "time", "isRecurring"]
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
        return <String, dynamic>{'error': 'API call failed: ${response.statusCode}'};
      }
    } catch (e) {
      // ignore: avoid_print
      print('AI Service: Error making API call: $e');
      return <String, dynamic>{'error': 'Network or parsing error: $e'};
    }
  }
}

// --- Screens ---

// Home Screen
class HomeScreen extends StatelessWidget {
  final String userId;
  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Watch for changes in ReminderProvider
    final ReminderProvider reminderProvider = context.watch<ReminderProvider>();
    final List<Reminder> reminders = reminderProvider.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reminders'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'User ID: $userId', // Display the mock user ID
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
          // No logout button since there's no auth
        ],
      ),
      body: reminders.isEmpty
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
                    'No reminders yet!',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap the + button to add one.',
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
                  key: ValueKey<String>(reminder.id), // Unique key for Dismissible
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
                        false; // Return false if dialog is dismissed without selection
                  },
                  onDismissed: (DismissDirection direction) {
                    context.read<ReminderProvider>().deleteReminder(reminder.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${reminder.title} dismissed')),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              AddEditReminderScreen(
                            userId: userId,
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
                      accentColor:
                          _getReminderColor(reminder.dateTime, reminder.isCompleted),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  AddEditReminderScreen(userId: userId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getReminderColor(DateTime reminderTime, bool isCompleted) {
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
}

// Add/Edit Reminder Screen
class AddEditReminderScreen extends StatefulWidget {
  final String userId;
  final Reminder? reminder; // Null for adding, non-null for editing

  const AddEditReminderScreen({Key? key, required this.userId, this.reminder})
      : super(key: key);

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AIService _aiService = AIService(); // AI service instance

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _aiInputController; // For AI text input
  late DateTime _selectedDateTime;
  late bool _isCompleted;
  late bool _isRecurring;
  bool _isParsingAI = false; // To show loading for AI

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _aiInputController = TextEditingController();

    if (widget.reminder != null) {
      // Editing an existing reminder
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description ?? '';
      _selectedDateTime = widget.reminder!.dateTime;
      _isCompleted = widget.reminder!.isCompleted;
      _isRecurring = widget.reminder!.isRecurring;
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
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _aiInputController.dispose();
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
        _titleController.text = parsedData['title'] as String? ?? _titleController.text;
        _descriptionController.text = parsedData['description'] as String? ?? _descriptionController.text;
        _isRecurring = parsedData['isRecurring'] as bool? ?? false;

        // Parse date and time
        try {
          final String dateString = parsedData['date'] as String;
          final String timeString = parsedData['time'] as String;
          final DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(dateString);
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
        createdAt: widget.reminder?.createdAt, // Keep original creation date if editing
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
        title:
            Text(widget.reminder == null ? 'Add New Reminder' : 'Edit Reminder'),
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
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _aiInputController,
                      decoration: const InputDecoration(
                        labelText: 'Describe your reminder',
                        hintText: 'e.g., "Meeting tomorrow at 10 AM with John"',
                        prefixIcon: Icon(Icons.smart_toy),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _isParsingAI
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _parseWithAI,
                          child: const Text('Parse with AI'),
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
                          DateFormat('yyyy-MM-dd').format(_selectedDateTime),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          DateFormat('HH:mm').format(_selectedDateTime),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Switches for Completion and Recurring
              SwitchListTile(
                title: const Text('Mark as Completed'),
                value: _isCompleted,
                onChanged: (bool value) {
                  setState(() {
                    _isCompleted = value;
                  });
                },
                secondary: const Icon(Icons.done_all),
                activeColor: Colors.green,
              ),
              SwitchListTile(
                title: const Text('Recurring Reminder'),
                value: _isRecurring,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
                secondary: const Icon(Icons.repeat),
                activeColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _saveReminder,
                  child: Text(
                      widget.reminder == null ? 'Add Reminder' : 'Update Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reminder Card Widget
class ReminderCard extends StatelessWidget {
  final String title;
  final String? description;
  final DateTime dateTime;
  final Color accentColor;
  final bool isCompleted;

  const ReminderCard({
    Key? key,
    required this.title,
    this.description,
    required this.dateTime,
    this.accentColor = Colors.blue,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          gradient: LinearGradient(
            colors: isCompleted
                ? <Color>[Colors.grey.shade300, Colors.grey.shade200]
                : <Color>[accentColor.withOpacity(0.9), accentColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isCompleted
              ? <BoxShadow>[]
              : <BoxShadow>[
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    isCompleted ? Icons.check_circle_outline : Icons.alarm,
                    color: isCompleted ? Colors.green.shade800 : Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isCompleted ? Colors.black87 : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (description != null && description!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: TextStyle(
                    color: isCompleted ? Colors.black54 : Colors.white70,
                    fontSize: 16,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '${DateFormat('MMM dd, yyyy').format(dateTime)} at ${DateFormat('hh:mm a').format(dateTime)}',
                  style: TextStyle(
                    color: isCompleted ? Colors.black45 : Colors.white60,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
