import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/chat/widgets/profile_status.dart';
import 'package:flutter/material.dart';

import '../../auth/widgets/star_field_background.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(child: _chatList()),
                _inputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 4),
          profileStatus(radius: 22, isActive: true),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saurav Kathayat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                SizedBox(width: 6),
                Text(
                  'Active now',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.call, color: gold),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: gold),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _chatList() {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            profileStatus(radius: 48, isActive: true),
            SizedBox(height: 4),
            Text(
              'Saurav Kathayat',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize: Size(0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'View Profile',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'TODAY',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: messages.length,
            reverse: true,
            itemBuilder: (context, index) {
              final message = messages[messages.length - 1 - index];
              return _chatBubble(
                message['text'],
                message['isUser'],
                message['time'],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chatBubble(String text, bool isUser, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[700], size: 18),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? gold.withOpacity(0.9)
                        : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? cardColor : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      if (isUser) ...[
                        SizedBox(width: 4),
                        Icon(Icons.done_all, size: 14, color: Colors.blue[300]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.attach_file, color: Colors.white70, size: 20),
              onPressed: () {},
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.mic, color: Colors.white70, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(Icons.send, color: cardColor, size: 22),
              onPressed: () {
                if (_controller.text.trim().isEmpty) return;

                final currentTime = TimeOfDay.now();
                final formattedTime =
                    '${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')} ${currentTime.period == DayPeriod.am ? 'AM' : 'PM'}';

                setState(() {
                  messages.add({
                    'text': _controller.text.trim(),
                    'isUser': true,
                    'time': formattedTime,
                  });

                  Future.delayed(Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() {
                        messages.add({
                          'text': "Celestial guide says: Be mindful today.",
                          'isUser': false,
                          'time': formattedTime,
                        });
                      });
                    }
                  });

                  _controller.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
