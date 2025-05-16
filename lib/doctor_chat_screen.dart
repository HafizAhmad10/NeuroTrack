import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DoctorChatScreen extends StatefulWidget {
  @override
  _DoctorChatScreenState createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  ChatSession? _chat;
  bool _isLoading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      await dotenv.load(fileName: ".env");
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(maxOutputTokens: 1000),
      );
      _chat = model.startChat();

      setState(() {
        _isLoading = false;
        _addBotMessage("Hello! I'm Dr. Neuro, your Parkinson's disease specialist assistant. How can I help you today?");
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _addBotMessage("Failed to initialize chat. Please check your connection and restart the app.");
      });
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_chat == null || _isLoading || _isTyping) return;

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Check if message is about Parkinson's
      final prompt = '''
      You are a medical assistant specialized in Parkinson's disease. 
      Only respond to questions about Parkinson's disease.
      If the question is not about Parkinson's, politely decline to answer.
      
      The user asked: "$message"
      
      Is this question about Parkinson's disease? Answer with only "yes" or "no".
      ''';

      final validationResponse = await _chat!.sendMessage(Content.text(prompt));
      final isValid = validationResponse.text?.toLowerCase().trim() == 'yes';

      if (!isValid) {
        _addBotMessage("I specialize in Parkinson's disease information. Please ask me questions related to Parkinson's.");
        setState(() => _isTyping = false);
        return;
      }

      // Get actual response
      final response = await _chat!.sendMessage(Content.text(message));
      _addBotMessage(response.text ?? "I couldn't process that request. Please try again.");
    } catch (e) {
      _addBotMessage("Sorry, I encountered an error. Please try again later.");
    } finally {
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. Neuro - Parkinson\'s Specialist'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Dr. Neuro'),
                  content: Text('I\'m an AI assistant specialized in Parkinson\'s disease information. I can answer your questions and provide helpful resources.'),
                  actions: [
                    TextButton(
                      child: Text('OK', style: TextStyle(color: Colors.indigo)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(top: 16, left: 8, right: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _messages[index],
              ),
            ),
            if (_isTyping)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.teal),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Dr. Neuro is typing...',
                              style: TextStyle(color: Colors.teal.shade800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask about Parkinson\'s disease...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.mic, color: Colors.indigo),
                            onPressed: () {}, // Add voice input functionality
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        enabled: !_isLoading && !_isTyping,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.indigo.shade400],
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading || _isTyping ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.teal.shade400,
                child: Icon(Icons.medical_services, size: 16, color: Colors.white),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.indigo.shade600
                        : Colors.teal.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 20 : 0),
                      topRight: Radius.circular(isUser ? 0 : 20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.grey.shade800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            Container(
              margin: EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.indigo.shade400,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}