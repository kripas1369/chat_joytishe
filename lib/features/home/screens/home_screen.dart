import 'package:chat_jyotishi/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../auth/widgets/star_field_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _sideDrawer(),
      body: Stack(
        children: [
          StarFieldBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    _homeHeader(),
                    SizedBox(height: 30),
                    _sectionTitle('Explore'),
                    SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _featureCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'Chat',
                          subtitle: 'Talk to astrologers',
                          onTap: () {
                            Navigator.of(context).pushNamed('/chat_list_screen');
                          },
                        ),
                        _featureCard(
                          icon: Icons.auto_awesome,
                          title: 'Horoscope',
                          subtitle: 'Daily predictions',
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed('/horoscope_screen');
                          },
                        ),
                        _featureCard(
                          icon: Icons.video_call_outlined,
                          title: 'Consultation',
                          subtitle: '1:1 live session',
                          onTap: () {},
                        ),
                        _featureCard(
                          icon: Icons.person_outline,
                          title: 'Profile',
                          subtitle: 'Your cosmic details',
                          onTap: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    _sectionTitle('Profile Management'),
                    SizedBox(height: 12),
                    _profileCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              child: Icon(Icons.menu, color: Colors.white),
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'CHAT',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: 'JYOTISH',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        InkWell(
          onTap: () {},
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Icon(Icons.notifications, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: cardColor2.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: gold),
            Spacer(),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: cardColor2.withOpacity(0.75),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage details & preferences',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed('/user_profile_screen');
            },
            child: Icon(Icons.arrow_forward_ios, size: 16, color: gold),
          ),
        ],
      ),
    );
  }

  Widget _sideDrawer() {
    return Drawer(
      backgroundColor: cardColor.withOpacity(0.95),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(gradient: cardColor2.withOpacity(0.75)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
                SizedBox(height: 12),
                Text(
                  'Praveen Shrestha',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'View & manage profile',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          _drawerItem(Icons.person_outline, 'Profile', () {
            Navigator.of(context).pushNamed('/user_profile_screen');
          }),
          _drawerItem(Icons.settings, 'Setting', () {
            Navigator.of(context).pushNamed('/set_password_screen');
          }),
          _drawerItem(Icons.phone, 'Contact', () {}),
          _drawerItem(Icons.privacy_tip_outlined, 'Privacy/Policy', () {}),
          _drawerItem(Icons.info_outline, 'About Us', () {}),
          _drawerItem(Icons.help_outline, 'Help', () {}),

          Divider(color: Colors.white24),
          _drawerItem(Icons.logout, 'Logout', () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: gold),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
