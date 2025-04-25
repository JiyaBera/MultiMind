import 'package:flutter/material.dart';
import 'package:ollama_dart/ollama_dart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/auth_service.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ollama Chat App',
      theme: ThemeData.dark(),
      home: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            return OllamaChatPage();
          }
          
          return LoginScreen();
        },
      ),
    );
  }
}

class OllamaChatPage extends StatefulWidget {
  @override
  _OllamaChatPageState createState() => _OllamaChatPageState();
}

class _OllamaChatPageState extends State<OllamaChatPage> {
  final _controller = TextEditingController();
  final List<ChatGroup> _chatGroups = [];
  bool _isLoading = false;
  final List<String> searchHistory = [];
  final _authService = AuthService();
  
  bool _isHistoryVisible = false;  // Controls search history visibility
  String? selectedPrompt;  // Tracks which prompt is selected to show

  final client = OllamaClient(
    baseUrl: 'https://cc87-136-233-130-145.ngrok-free.app/api',
  );

  final List<String> models = ['llama3.1:latest', 'gemma2:9b', 'mistral-nemo:latest'];

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final padding = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Model Comparison'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isHistoryVisible = !_isHistoryVisible;
            });
          },
        ),
        actions: [
          StreamBuilder<User?>(
            stream: _authService.authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return PopupMenuButton<String>(
                  icon: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        snapshot.data!.email!.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await _handleLogout();
                    } else if (value == 'profile') {
                      _showProfileDialog(context, snapshot.data!);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person),
                          SizedBox(width: 8),
                          Text('Account Info'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return SizedBox.shrink();
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                // Input Section
                Container(
                  constraints: BoxConstraints(maxWidth: isSmallScreen ? double.infinity : 800),
                  margin: EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Enter your prompt',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _sendMessage(_controller.text),
                        child: Text('Generate Responses'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, isSmallScreen ? 45 : 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isLoading) LinearProgressIndicator(),

                // Display selected chat or all chats if none selected
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (selectedPrompt != null)
                          // Show only the selected chat
                          ...(_chatGroups
                              .where((group) => group.prompt == selectedPrompt)
                              .map((group) => ChatGroupWidget(group: group))),
                        if (selectedPrompt == null)
                          // Show all chats if nothing is selected
                          ...(_chatGroups.map((group) => ChatGroupWidget(group: group))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search History Overlay - Only visible when _isHistoryVisible is true
          if (_isHistoryVisible)
            Container(
              color: Colors.black54,
              child: Row(
                children: [
                  // Search History Sidebar
                  Container(
                    width: isSmallScreen ? screenSize.width * 0.8 : 300,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        // Search History Header
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade800),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Search History',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _isHistoryVisible = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        // Search History List
                        Expanded(
                          child: ListView.builder(
                            itemCount: searchHistory.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  searchHistory[index],
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedPrompt = searchHistory[index];
                                    _isHistoryVisible = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Transparent area to close sidebar when clicked
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isHistoryVisible = false;
                        });
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Account Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user.email!.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('Email'),
                subtitle: Text(user.email ?? 'No email'),
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.verified_user),
                title: Text('Email Verified'),
                subtitle: Text(user.emailVerified ? 'Yes' : 'No'),
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.access_time),
                title: Text('Last Sign In'),
                subtitle: Text(user.metadata.lastSignInTime?.toString() ?? 'Unknown'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      if (!searchHistory.contains(text)) {
        searchHistory.insert(0, text);
      }
      selectedPrompt = null;  // Reset selected prompt to show all chats
    });

    List<ChatMessage> responses = [];

    for (String model in models) {
      final request = GenerateCompletionRequest(model: model, prompt: text, stream: false);
      final now = DateTime.now();

      try {
        final generated = await client.generateCompletion(request: request);
        responses.add(ChatMessage(text: generated.response.toString(), model: model, timestamp: now));
      } catch (e) {
        responses.add(ChatMessage(text: 'Error in model $model: $e', model: model, timestamp: now));
      }
    }

    setState(() {
      _chatGroups.add(ChatGroup(prompt: text, responses: responses));
      _isLoading = false;
    });

    _controller.clear();
  }
}

class ChatGroup {
  final String prompt;
  final List<ChatMessage> responses;

  ChatGroup({required this.prompt, required this.responses});
}

class ChatMessage {
  final String text;
  final String model;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.model, required this.timestamp});
}

class ChatGroupWidget extends StatelessWidget {
  final ChatGroup group;

  const ChatGroupWidget({
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final padding = isSmallScreen ? 8.0 : 16.0;

    return Container(
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prompt: ${group.prompt}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          isSmallScreen
              ? Column(
                  children: group.responses.map((response) => ModelCard(response: response)).toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: group.responses.map((response) => Expanded(
                    child: ModelCard(response: response),
                  )).toList(),
                ),
        ],
      ),
    );
  }
}

class ModelCard extends StatelessWidget {
  final ChatMessage response;

  const ModelCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final padding = isSmallScreen ? 8.0 : 16.0;
    final margin = isSmallScreen ? 4.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(padding),
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade800),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  response.model,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${response.timestamp.toLocal()}'.split('.')[0],
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            response.text,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

