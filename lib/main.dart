import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // ✅ rootBundle के लिए
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const InnerPeaceApp());
}

class InnerPeaceApp extends StatelessWidget {
  const InnerPeaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inner Peace AI',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const InnerPeaceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InnerPeaceScreen extends StatefulWidget {
  const InnerPeaceScreen({super.key});

  @override
  State<InnerPeaceScreen> createState() => _InnerPeaceScreenState();
}

class _InnerPeaceScreenState extends State<InnerPeaceScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _apiKey;
  String? _model;
  String? _systemPrompt;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  // ✅ CORRECT - Web के लिए सही तरीका
  Future<void> _loadConfig() async {
    try {
      // ✅ सिर्फ ये 3 lines - बिना File, exists, readAsString के
      final yamlString = await rootBundle.loadString('assets/config.yaml');
      final yamlMap = loadYaml(yamlString);
      final config = Map<String, dynamic>.from(yamlMap);

      setState(() {
        _apiKey = config['ai']['api_key'];
        _model = config['ai']['model'];
        _systemPrompt = config['prompts']['system_prompt'];
        _isInitialized = true;
      });

      _addMessage(Message(
        text: '🌿 Hello! I\'m your Inner Peace AI Consultant.\nHow are you feeling today?',
        isUser: false,
      ));
    } catch (e) {
      _addMessage(Message(
        text: '❌ Error: $e\nPlease check assets/config.yaml',
        isUser: false,
      ));
    }
  }

  void _addMessage(Message message) {
    setState(() {
      _messages.add(message);
    });
  }

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty || _isLoading) return;

    _addMessage(Message(text: userInput, isUser: true));
    _controller.clear();
    setState(() => _isLoading = true);

    final response = await _getAIPromptResponse(
      apiKey: _apiKey!,
      model: _model!,
      systemPrompt: _systemPrompt!,
      userMessage: userInput,
    );

    setState(() => _isLoading = false);
    _addMessage(Message(text: response, isUser: false));
  }

  // Bytez API Call
  Future<String> _getAIPromptResponse({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.7,
  }) async {
    final url = Uri.parse('https://api.bytez.com/v1/chat/completions');

    final requestBody = {
      "model": model,
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": userMessage}
      ],
      "temperature": temperature,
      "max_tokens": 500
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey"
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "⚠️ API Error ${response.statusCode}";
      }
    } catch (e) {
      return "⚠️ Connection Error: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧘 Inner Peace AI'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.teal.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _isInitialized
                          ? 'Type your message...'
                          : 'Loading...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: _isInitialized && !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _isInitialized && !_isLoading
                      ? _sendMessage
                      : null,
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}