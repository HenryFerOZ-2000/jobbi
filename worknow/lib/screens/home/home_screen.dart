import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../services/fcm_service.dart';
import '../../services/favorites_service.dart';
import '../../widgets/custom_bottom_navbar.dart';
import 'tabs/jobs_tab.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/profile_tab.dart';
import '../jobs/my_jobs_screen.dart';
import '../auth/profile_setup/profile_setup_flow.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    JobsTab(),
    FavoritesTab(),
    MyJobsScreen(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
    _updateFcmToken();
    _loadFavorites();
  }

  // Load user favorites
  Future<void> _loadFavorites() async {
    try {
      await FavoritesService.instance.loadUserFavorites();
    } catch (e) {
      // Silent fail - non-critical
      debugPrint('Error loading favorites: $e');
    }
  }

  // Update FCM token when user enters home screen
  Future<void> _updateFcmToken() async {
    try {
      await FCMService.instance.updateFcmToken();
    } catch (e) {
      // Silent fail - non-critical
      debugPrint('Error updating FCM token: $e');
    }
  }

  Future<void> _checkProfileCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final profileCompleted = userDoc.data()?['profileCompleted'] ?? false;

      if (!profileCompleted && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileSetupFlow(),
          ),
        );
      }
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: _tabs[_currentIndex],
      extendBody: true,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

