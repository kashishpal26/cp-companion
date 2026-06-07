import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- GLOBAL THEME STATE ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  runApp(const CPCompanionApp());
}

class CPCompanionApp extends StatelessWidget {
  const CPCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'CP Companion',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: Colors.grey[100],
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          themeMode: currentMode,
          home: const MainNavigation(),
        );
      },
    );
  }
}

// --- MAIN SHELL & NAVIGATION ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  // THE FIX: Pointed the second tab to our new SnippetVault!
  final List<Widget> _screens = [
    const ContestTracker(),
    const SnippetVault(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.rocket_launch), label: 'Live Contests'),
          NavigationDestination(icon: Icon(Icons.code), label: 'Snippet Vault'),
        ],
      ),
    );
  }
}

// --- SCREEN 1: CONTEST TRACKER ---
class ContestTracker extends StatefulWidget {
  const ContestTracker({super.key});

  @override
  State<ContestTracker> createState() => _ContestTrackerState();
}

class _ContestTrackerState extends State<ContestTracker> {
  List contests = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchContests();
  }

  Color getPlatformColor(String site) {
    switch (site.toLowerCase()) {
      case 'leetcode': return Colors.orange;
      case 'codeforces': return Colors.blueAccent;
      case 'hackerrank': return Colors.green;
      case 'atcoder': return Colors.purpleAccent;
      case 'codechef': return Colors.brown;
      default: return Colors.grey;
    }
  }

  Future<void> fetchContests() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/contests'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          contests = data['contests'] ?? [];
          if (data.containsKey('error')) errorMessage = data['error'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        contests = [];
        errorMessage = "Failed to connect to backend.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Tracker', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(themeNotifier.value == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchContests,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text('Error: $errorMessage', style: const TextStyle(color: Colors.redAccent)))
                : contests.isEmpty
                    ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('No contests found.')))])
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: contests.length,
                        itemBuilder: (context, index) {
                          final contest = contests[index];
                          final platformColor = getPlatformColor(contest['site'] ?? '');
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(contest['site'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                        backgroundColor: platformColor,
                                        padding: EdgeInsets.zero,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(contest['start_time'] ?? 'Unknown', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                        ],
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    contest['name'] ?? 'Unknown',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// --- SCREEN 2: THE SNIPPET VAULT ---
class SnippetVault extends StatefulWidget {
  const SnippetVault({super.key});

  @override
  State<SnippetVault> createState() => _SnippetVaultState();
}

class _SnippetVaultState extends State<SnippetVault> {
  List snippets = [];
  bool isLoading = true;

  // Controllers to grab the text typed by the user
  final TextEditingController titleController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSnippets();
  }

  // 1. GET Request: Fetch templates from SQLite Database
  Future<void> fetchSnippets() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/snippets'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          snippets = data['snippets'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching snippets: $e");
      setState(() => isLoading = false);
    }
  }

  // 2. POST Request: Send new template to Python backend
  Future<void> submitSnippet() async {
    if (titleController.text.isEmpty || codeController.text.isEmpty) return;

    try {
      await http.post(
        Uri.parse('http://127.0.0.1:8000/snippets'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': titleController.text,
          'tag': tagController.text.isEmpty ? 'General' : tagController.text,
          'code_block': codeController.text,
        }),
      );
      
      // Clean up the form and refresh the screen!
      titleController.clear();
      tagController.clear();
      codeController.clear();
      Navigator.pop(context); // Closes the bottom sheet
      fetchSnippets(); // Grabs the fresh data from the DB
      
    } catch (e) {
      print("Error saving snippet: $e");
    }
  }

  // 3. The Form UI
  void showAddSnippetForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to expand above keyboard
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Pushes UI up when keyboard opens
            left: 16, right: 16, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Add C++ Template", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController, 
                decoration: const InputDecoration(labelText: 'Title (e.g., Fast I/O)', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagController, 
                decoration: const InputDecoration(labelText: 'Tag (e.g., Setup)', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                maxLines: 6, // Makes the box tall like an IDE
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13), // Hacker font!
                decoration: const InputDecoration(
                  labelText: 'Code', 
                  border: OutlineInputBorder(), 
                  filled: true, 
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitSnippet,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("Save to Database", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  // 4. The List UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snippet Vault', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      // THE ADD BUTTON!
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddSnippetForm,
        icon: const Icon(Icons.add),
        label: const Text("New Snippet"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : snippets.isEmpty
              ? const Center(child: Text("Your vault is empty. Add a template!"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: snippets.length,
                  itemBuilder: (context, index) {
                    final snippet = snippets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(snippet['title'] ?? 'Untitled', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Chip(label: Text(snippet['tag'] ?? 'General', style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // The Dark Code Block UI
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                snippet['code_block'] ?? '',
                                style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}