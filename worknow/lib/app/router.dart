import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/auth/profile_setup/profile_setup_flow.dart';
import '../screens/home/home_screen.dart';
import '../screens/jobs/create_job_screen.dart';
import '../screens/jobs/job_details_screen.dart';
import '../screens/jobs/my_jobs_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/view_profile_screen.dart';
import '../screens/profile/create_profile_screen.dart';
import '../screens/profile/edit_user_profile_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/users/users_search_screen.dart';
import '../screens/ratings/rate_user_screen.dart';

class AppRouter {
  static const String login = '/';
  static const String register = '/register';
  static const String completeProfile = '/complete-profile';
  static const String profileSetupFlow = '/profile-setup-flow';
  static const String createProfile = '/create-profile';
  static const String editUserProfile = '/edit-user-profile';
  static const String home = '/home';
  static const String createJob = '/create-job';
  static const String jobDetails = '/job-details';
  static const String myJobs = '/my-jobs';
  static const String profile = '/profile';
  static const String viewProfile = '/view-profile';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String usersSearch = '/users-search';
  static const String rateUser = '/rate-user';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case completeProfile:
        return MaterialPageRoute(builder: (_) => const CompleteProfileScreen());
      
      case profileSetupFlow:
        return MaterialPageRoute(builder: (_) => const ProfileSetupFlow());
      
      case createProfile:
        return MaterialPageRoute(builder: (_) => const CreateProfileScreen());
      
      case editUserProfile:
        return MaterialPageRoute(builder: (_) => const EditUserProfileScreen());
      
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case createJob:
        return MaterialPageRoute(builder: (_) => const CreateJobScreen());
      
      case myJobs:
        return MaterialPageRoute(builder: (_) => const MyJobsScreen());
      
      case profile:
        final uid = routeSettings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: uid),
        );
      
      case viewProfile:
        return MaterialPageRoute(
          builder: (_) => const ViewProfileScreen(),
        );
      
      case jobDetails:
        final args = routeSettings.arguments as Map<String, dynamic>;
        final jobId = args['jobId'] as String;
        return MaterialPageRoute(
          builder: (_) => JobDetailsScreen(jobId: jobId),
        );
      
      case chat:
        final args = routeSettings.arguments as Map<String, dynamic>;
        final chatId = args['chatId'] as String;
        final otherUserName = args['otherUserName'] as String;
        final jobTitle = args['jobTitle'] as String;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserName: otherUserName,
            jobTitle: jobTitle,
          ),
        );
      
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      case usersSearch:
        return MaterialPageRoute(builder: (_) => const UsersSearchScreen());
      
      case rateUser:
        final args = routeSettings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => RateUserScreen(
            jobId: args['jobId'] as String,
            userId: args['userId'] as String,
            userName: args['userName'] as String,
            jobTitle: args['jobTitle'] as String,
          ),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}

