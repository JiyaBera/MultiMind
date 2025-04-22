import 'package:flutter/material.dart';
import 'package:ollama_dart/ollama_dart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ollama Chat App',
      theme: ThemeData.dark(),
      home: OllamaChatPage(),
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
  
  bool _isHistoryVisible = false;  // Controls search history visibility
  String? selectedPrompt;  // Tracks which prompt is selected to show

  final client = OllamaClient(
    baseUrl: 'https://709c-136-233-130-145.ngrok-free.app/api',
  );

  final List<String> models = ['llama3.1:latest', 'gemma2:9b', 'mistral-nemo:latest'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Model Comparison'),
        leading: IconButton(  // Three-dash menu
          icon: Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isHistoryVisible = !_isHistoryVisible;  // Toggle search history
            });
          },
        ),
      ),
      body: Stack(
        children: [
          // Main Content
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Input Section
                Container(
                  constraints: BoxConstraints(maxWidth: 800),
                  margin: EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Enter your prompt',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _sendMessage(_controller.text),
                        child: Text('Generate Responses'),
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
              color: Colors.black54,  // Semi-transparent overlay
              child: Row(
                children: [
                  // Search History Sidebar
                  Container(
                    width: 300,
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
                                  fontSize: 20,
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
                                title: Text(searchHistory[index]),
                                onTap: () {
                                  setState(() {
                                    selectedPrompt = searchHistory[index];
                                    _isHistoryVisible = false;  // Hide search history
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
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prompt: ${group.prompt}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...group.responses.map((response) => ModelCard(response: response)),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                response.model,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${response.timestamp.toLocal()}'.split('.')[0],
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(response.text),
        ],
      ),
    );
  }
}
