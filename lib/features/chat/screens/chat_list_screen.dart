import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/chat/widgets/profile_status.dart';
import 'package:flutter/material.dart';
import '../../auth/widgets/star_field_background.dart';
import '../models/active_user_model.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  SizedBox(height: 16),
                  _searchBar(),
                  SizedBox(height: 20),
                  _activeNowSection(),
                  SizedBox(height: 20),
                  Expanded(child: _chatList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Icon(Icons.edit_outlined, color: Colors.white),
            SizedBox(width: 16),
            Icon(Icons.more_vert, color: Colors.white),
          ],
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      height: 42,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.white54),
          SizedBox(width: 8),
          Text('Search...', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _activeNowSection() {
    final List<ActiveUser> activeUsers = [
      ActiveUser(name: 'Alice', isActive: true),
      ActiveUser(name: 'Sarah', isActive: true),
      ActiveUser(name: 'Mike', isActive: true),
      ActiveUser(name: 'Jessica', isActive: false),
      ActiveUser(name: 'David', isActive: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE NOW',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),

        SizedBox(height: 12),

        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: activeUsers.length,
            separatorBuilder: (_, __) => SizedBox(width: 16),
            itemBuilder: (context, index) {
              final user = activeUsers[index];

              return Column(
                children: [
                  profileStatus(
                    radius: 30, // bigger circle
                    isActive: user.isActive,
                    profileImageUrl: user.imageUrl,
                  ),

                  SizedBox(height: 6),

                  SizedBox(
                    width: 64,
                    child: Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chatList() {
    return ListView(
      children: [
        _chatTile(
          name: 'Alice Chen',
          message: "That sounds great! Let's discuss more in the meeting.",
          time: '5 minutes',
          online: true,
          seen: true,
        ),
        SizedBox(height: 8),
        _chatTile(
          name: 'Bob Johnson',
          message: 'See you tomorrow at 10am',
          time: 'about 3 hours',
          unread: 2,
        ),
        SizedBox(height: 8),
        _chatTile(
          name: 'Design Team',
          message: 'Sarah: The new mockups are looking great!',
          time: '1 day',
          online: true,
          seen: true,
        ),
        SizedBox(height: 8),
        _chatTile(
          name: 'Emma Wilson',
          message: "Thanks for the feedback! I'll update it.",
          time: '3 days',
        ),
      ],
    );
  }

  Widget _chatTile({
    required String name,
    required String message,
    required String time,
    bool online = false,
    bool seen = false,
    int unread = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.grey[700]),
                ),
                if (online)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                    ),
                  ),
                if (unread > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unread.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                SizedBox(height: 6),
                Icon(
                  seen ? Icons.done_all : Icons.done,
                  size: 16,
                  color: seen ? Colors.blueAccent : Colors.white54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
