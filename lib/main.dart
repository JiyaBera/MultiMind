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

  final client = OllamaClient(
    baseUrl: 'https://709c-136-233-130-145.ngrok-free.app/api',
  );

  final List<String> models = ['llama3.1:latest', 'gemma2:9b', 'mistral-nemo:latest'];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Model Comparison')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter your prompt:',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _sendMessage(_controller.text),
              child: Text('Generate Responses'),
            ),
            SizedBox(height: 20),
            if (_isLoading) LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _chatGroups.length,
                itemBuilder: (context, index) {
                  final group = _chatGroups[index];
                  return ChatGroupWidget(group: group);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatGroupWidget extends StatelessWidget {
  final ChatGroup group;

  const ChatGroupWidget({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prompt: ${group.prompt}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ...group.responses.map((response) => ModelCard(response: response)).toList(),
        Divider(),
      ],
    );
  }
}

class ModelCard extends StatelessWidget {
  final ChatMessage response;

  const ModelCard({required this.response});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      color: Colors.grey[850],
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(response.model, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${response.timestamp.toLocal()}'.split('.')[0], style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            SizedBox(height: 8),
            Text(response.text),
          ],
        ),
      ),
    );
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
