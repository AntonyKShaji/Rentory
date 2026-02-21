import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../widgets/app_widgets.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.propertyId, required this.propertyName, required this.senderId});
  final String propertyId;
  final String propertyName;
  final String senderId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _api = ApiService();
  final TextEditingController _message = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  Timer? _poller;
  bool _loading = true;
  String? _pendingImage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _message.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final rows = await _api.getChatMessages(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _messages = rows;
        _loading = false;
      });
      _jumpToBottom();
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _pickChatImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.path.toLowerCase().endsWith('png') ? 'png' : 'jpeg';
    final dataUri = 'data:image/$ext;base64,${base64Encode(bytes)}';
    if (dataUri.length > 1000000) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected image is too large. Please choose a smaller image.')),
      );
      return;
    }
    setState(() => _pendingImage = dataUri);
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    final local = {
      'sender_id': widget.senderId,
      'sender_name': 'You',
      'text': text.isEmpty ? null : text,
      'image_url': _pendingImage,
    };
    setState(() {
      _messages = [..._messages, local];
      _message.clear();
      _pendingImage = null;
    });
    _jumpToBottom();

    try {
      await _api.sendChatMessage(propertyId: widget.propertyId, senderId: widget.senderId, text: local['text'] as String?, imageUrl: local['image_url'] as String?);
      _loadMessages(silent: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.propertyName), centerTitle: false),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE8F1F3), Color(0xFFF4F7F8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final row = _messages[index];
                        final mine = row['sender_id'] == widget.senderId;
                        return ChatBubble(
                          isMine: mine,
                          sender: (row['sender_name'] as String?) ?? 'User',
                          text: row['text'] as String?,
                          imageUrl: row['image_url'] as String?,
                        );
                      },
                    ),
            ),
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Stack(
                  children: [
                    RemoteOrDataImage(imageRef: _pendingImage, height: 90, width: 90),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () => setState(() => _pendingImage = null),
                        child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Row(
                  children: [
                    IconButton(onPressed: _pickChatImage, icon: const Icon(Icons.attach_file_rounded)),
                    Expanded(child: TextField(controller: _message, decoration: const InputDecoration(hintText: 'Type a message...'))),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _send, style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(14)), child: const Icon(Icons.send)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
