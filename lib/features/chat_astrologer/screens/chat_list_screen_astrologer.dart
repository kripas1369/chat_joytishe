import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_screen.dart';
import 'package:chat_jyotishi/features/chat/widgets/profile_status.dart';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';

class AstrologerChatListScreen extends StatefulWidget {
  const AstrologerChatListScreen({super.key});

  @override
  State<AstrologerChatListScreen> createState() =>
      _AstrologerChatListScreenState();
}

class _AstrologerChatListScreenState extends State<AstrologerChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          ),

          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryPurple.withOpacity(0.01),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      _header(context),
                      SizedBox(height: 16),
                      _searchBar(),
                      SizedBox(height: 8),
                      _statsRow(),
                    ],
                  ),
                ),

                // Chat list
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _chatList(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        GlassIconButton(
          onTap: () => Navigator.pushReplacementNamed(
            context,
            '/home_screen_astrologer',
          ),
          icon: Icons.arrow_back_ios_new_rounded,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Notification badge
        GlassIconButton(onTap: () {}, icon: Icons.refresh),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statChip(
          icon: Icons.people_outline,
          label: 'Active',
          value: '3',
          color: Colors.greenAccent,
        ),
        SizedBox(width: 8),
        _statChip(
          icon: Icons.schedule,
          label: 'Pending',
          value: '2',
          color: Colors.orangeAccent,
        ),
        SizedBox(width: 8),
        _statChip(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          value: '24',
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 2),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withOpacity(0.12),
            AppColors.deepPurple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.white60, size: 20),
          hintText: 'Search clients...',
          hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white54, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _chatList(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 16),
      itemCount: 6,
      separatorBuilder: (_, __) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _clientChatTile(
          context: context,
          clientName: 'Client ${index + 1}',
          lastMessage: 'Thank you for the guidance 🙏',
          time: index == 0 ? 'Just now' : '${index * 5}m',
          unreadCount: index == 0 ? 3 : (index == 2 ? 1 : 0),
          isOnline: index.isEven,
          isSessionActive: index == 0,
        );
      },
    );
  }

  Widget _clientChatTile({
    required BuildContext context,
    required String clientName,
    required String lastMessage,
    required String time,
    required bool isOnline,
    required bool isSessionActive,
    required int unreadCount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: 'dummy_chat_id',
              otherUserId: 'client_id',
              otherUserName: clientName,
              otherUserPhoto: '',
              currentUserId: 'astrologer_id',
              accessToken: '',
              refreshToken: '',
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withOpacity(0.12),
              AppColors.deepPurple.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1.5,
            color: isSessionActive
                ? Colors.greenAccent.withOpacity(0.4)
                : AppColors.primaryPurple.withOpacity(0.25),
          ),
          boxShadow: isSessionActive
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            profileStatus(radius: 28, isActive: isOnline, name: clientName),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clientName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (isSessionActive)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.greenAccent.shade100,
                                Colors.greenAccent.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.white70 : Colors.white54,
                      fontSize: 13,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: unreadCount > 0 ? Colors.white70 : Colors.white54,
                    fontSize: 11,
                    fontWeight: unreadCount > 0
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8),
                if (unreadCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurple,
                          AppColors.primaryPurple.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(Icons.check, color: Colors.white38, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
