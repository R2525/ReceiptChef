// lib/screens/chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/generative_ai_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _receiptIdToUpdateDate;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: "안녕하세요! 가지고 계신 식자재에 대해 무엇이든 물어보세요. 영수증 분석은 상단의 카메라 아이콘을 눌러주세요.",
      isUser: false,
    ));
  }

  Future<void> _analyzeReceipt(ImageSource source) async {
    try {
      final XFile? imageFile = await _picker.pickImage(source: source);
      if (imageFile == null) return;

      setState(() => _isLoading = true);

      final jsonData = await GenerativeAIService.analyzeReceiptFromImage(File(imageFile.path));
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final newReceipt = await authProvider.addReceiptFromJson(jsonData, File(imageFile.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('영수증이 성공적으로 등록되었습니다!')),
        );
        if (newReceipt.isDateEstimated) {
          _receiptIdToUpdateDate = newReceipt.id;
          setState(() {
            _messages.add(ChatMessage(
              text: "영수증에서 날짜를 찾을 수 없어 오늘 날짜로 설정했어요. 구매 날짜가 다른가요? (YYYY-MM-DD 형식으로 알려주세요)",
              isUser: false,
            ));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendMessage() async {
    final userMessage = _textController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final intentData = await GenerativeAIService.interpretUserIntent(userMessage);
      final intent = intentData['intent'];
      final target = intentData['target'];
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      String aiResponseText;

      switch (intent) {
        case 'delete_item':
          final itemName = target as String;
          final success = await authProvider.deleteIngredientByName(itemName);
          aiResponseText = success
              ? "'$itemName'을(를) 식자재 목록에서 삭제했어요."
              : "'$itemName'은(는) 식자재 목록에 없어요.";
          break;
        
        case 'update_date':
          if (_receiptIdToUpdateDate != null) {
            final newDate = DateTime.parse(target as String);
            await authProvider.updateReceiptDate(_receiptIdToUpdateDate!, newDate);
            aiResponseText = "${DateFormat('yyyy년 MM월 dd일').format(newDate)}로 날짜를 수정했어요. 또 궁금한 점이 있으신가요?";
            _receiptIdToUpdateDate = null;
          } else {
            aiResponseText = "어떤 영수증의 날짜를 수정할까요? 먼저 영수증을 분석해주세요.";
          }
          break;

        default: // 'chat'
          final ingredients = authProvider.ingredients;
          aiResponseText = await GenerativeAIService.getChatResponse(userMessage, ingredients);
          break;
      }

      setState(() {
        _messages.add(ChatMessage(text: aiResponseText, isUser: false));
      });

    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "죄송합니다, 오류가 발생했어요.", isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _showImageSourceActionSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.primary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _handleSendMessage(),
                decoration: const InputDecoration.collapsed(hintText: '레시피 추천, 소비기한 등 질문해보세요'),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isLoading ? null : _handleSendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 촬영하기'),
                onTap: () {
                  Navigator.of(context).pop();
                  _analyzeReceipt(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('앨범에서 선택하기'),
                onTap: () {
                  Navigator.of(context).pop();
                  _analyzeReceipt(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}