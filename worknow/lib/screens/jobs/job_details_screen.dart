import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/image_card.dart';
import '../../widgets/verified_badge.dart';
import '../../services/chat_service.dart';
import '../../services/rating_service.dart';
import '../../services/employer_review_service.dart';
import '../../services/application_service.dart';
import '../../controllers/job_status_controller.dart';
import '../../utils/verification_helper.dart';
import 'applicants_list_screen.dart';
import '../chat/chat_screen.dart';
import '../ratings/rate_user_screen.dart';
import '../ratings/rate_employer_screen.dart';
import '../profile/employer_profile_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _applyToJob(BuildContext context, Map<String, dynamic> jobData) async {
    if (_isApplying) return;

    // Check verification first
    final isVerified = await VerificationHelper.checkVerificationAndShowDialog(context);
    if (!isVerified) {
      return;
    }

    // Check if job has available slots
    final isClosed = jobData['isClosed'] ?? false;
    final totalSlots = jobData['totalSlots'] ?? 1;
    final filledSlots = jobData['filledSlots'] ?? 0;

    if (isClosed || filledSlots >= totalSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Este trabajo ya no tiene cupos disponibles'),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isApplying = true);

    try {
      final employerId = jobData['ownerId'] ?? '';
      final jobTitle = jobData['title'] ?? 'Trabajo';

      if (employerId.isEmpty) {
        throw 'Información del empleador no disponible';
      }

      // Use ApplicationService to apply - it creates chat and sends notification automatically
      await ApplicationService.instance.applyToJob(
        jobId: widget.jobId,
        employerId: employerId,
        jobTitle: jobTitle,
        message: '', // Optional: can add a message dialog before applying
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('✓ Postulación enviada y chat creado'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  /// Request completion of work (worker marks as completed)
  Future<void> _requestCompletion(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como Completado'),
        content: const Text(
          '¿Has finalizado este trabajo? El empleador deberá confirmar la finalización.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }

      // Request completion
      final JobStatusController statusController = JobStatusController.instance;
      await statusController.requestCompletion(
        jobId: widget.jobId,
        userId: currentUser.uid,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Solicitud enviada. Esperando confirmación del empleador.'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Refresh the screen
        setState(() {});
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _openChat(BuildContext context, Map<String, dynamic> jobData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final chatService = ChatService.instance;
      final hiredCandidate = jobData['hiredCandidate'] as Map<String, dynamic>?;

      if (hiredCandidate == null) {
        throw 'No hay candidato seleccionado';
      }

      final chatId = await chatService.getChatIdByJobAndUser(
        jobId: widget.jobId,
        userId: currentUser.uid,
      );

      if (chatId == null) {
        throw 'Chat no encontrado';
      }

      if (mounted) {
        final ownerId = jobData['ownerId'] ?? '';
        final otherUserName = currentUser.uid == ownerId
            ? hiredCandidate['name'] ?? 'Usuario'
            : 'Empleador';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserName: otherUserName,
              jobTitle: jobData['title'] ?? 'Trabajo',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trabajo no encontrado',
                    style: AppTextStyles.h5,
                  ),
                ],
              ),
            ),
          );
        }

        final jobData = snapshot.data!.data() as Map<String, dynamic>;
        final currentUser = FirebaseAuth.instance.currentUser;

        // Extract job data
        final title = jobData['title'] ?? 'Sin título';
        final description = jobData['description'] ?? '';
        final category = jobData['category'] ?? 'Sin categoría';
        final city = jobData['city'] ?? 'Ciudad';
        final country = jobData['country'] ?? 'País';
        final budget = jobData['budget'] ?? 0;
        final duration = jobData['duration'] ?? 'No especificado';
        final requirements = jobData['requirements'] ?? 'No especificado';
        final status = jobData['status'] ?? 'open';
        final ownerId = jobData['ownerId'] ?? '';
        final applicantsIds = List<String>.from(jobData['applicantsIds'] ?? []);
        final hiredCandidate = jobData['hiredCandidate'] as Map<String, dynamic>?;
        final createdAt = jobData['createdAt'] as Timestamp?;

        final isOwner = currentUser?.uid == ownerId;
        final hasApplied = currentUser != null && applicantsIds.contains(currentUser.uid);
        final isHired = hiredCandidate != null && hiredCandidate['uid'] == currentUser?.uid;

        // Format date
        String dateText = 'Recién publicado';
        if (createdAt != null) {
          final date = createdAt.toDate();
          dateText = 'Publicado el ${DateFormat('dd MMM yyyy').format(date)}';
        }

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: CustomScrollView(
            slivers: [
              // Large Image Header (Airbnb style)
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: ImageCard(
                    imageUrl: null, // Add image URL when available
                    height: 300,
                    borderRadius: 0,
                    placeholder: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.work_rounded,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.shadowSoft,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -30, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Category Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category and Status Chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppChip(
                                  label: category,
                                  icon: Icons.category_outlined,
                                  type: AppChipType.category,
                                ),
                                _buildStatusChip(status),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Job Title
                            Text(
                              title,
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Location and Budget
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 20,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$city, $country',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Budget
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: AppColors.shadowSoft,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.payments_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${budget.toStringAsFixed(2)}',
                                    style: AppTextStyles.priceLarge.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Employer Info
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                              builder: (context, ownerSnapshot) {
                                if (ownerSnapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: AppColors.shadowSoft,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }

                                if (ownerSnapshot.hasData && ownerSnapshot.data != null) {
                                  final ownerData = ownerSnapshot.data!.data() as Map<String, dynamic>?;
                                  if (ownerData != null) {
                                    // Get name from multiple possible fields
                                    String employerName = ownerData['fullName'] ?? ownerData['name'] ?? '';
                                    if (employerName.isEmpty) {
                                      final nombre = ownerData['nombre'] ?? '';
                                      final apellido = ownerData['apellido'] ?? '';
                                      employerName = '$nombre $apellido'.trim();
                                    }
                                    if (employerName.isEmpty) {
                                      employerName = 'Empleador';
                                    }

                                    final employerEmail = ownerData['email'] ?? '';
                                    final employerCity = ownerData['city'] ?? ownerData['ciudad'] ?? '';
                                    final employerCountry = ownerData['country'] ?? ownerData['pais'] ?? '';
                                    final employerPhoto = ownerData['photoUrl'] ?? ownerData['profileImage'];
                                    final employerRating = (ownerData['employerRatingAverage'] ?? 0.0) is int
                                        ? (ownerData['employerRatingAverage'] as int).toDouble()
                                        : (ownerData['employerRatingAverage'] ?? 0.0);
                                    final employerRatingCount = ownerData['employerRatingCount'] ?? 0;
                                    final employerVerified = ownerData['verificationStatus'] == 'verified';

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EmployerProfileScreen(employerId: ownerId),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: AppColors.shadowSoft,
                                            ),
                                            child: employerPhoto != null && employerPhoto.toString().isNotEmpty
                                                ? CircleAvatar(
                                                    radius: 25,
                                                    backgroundImage: NetworkImage(employerPhoto),
                                                    backgroundColor: AppColors.primaryLight,
                                                  )
                                                : CircleAvatar(
                                                    radius: 25,
                                                    backgroundColor: AppColors.primary,
                                                    child: Text(
                                                      employerName.isNotEmpty
                                                          ? employerName[0].toUpperCase()
                                                          : 'E',
                                                      style: AppTextStyles.h5.copyWith(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.business_rounded,
                                                      size: 14,
                                                      color: AppColors.textTertiary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Empleador',
                                                      style: AppTextStyles.caption.copyWith(
                                                        color: AppColors.textTertiary,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        employerName,
                                                        style: AppTextStyles.bodyMedium.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 15,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (employerVerified) ...[
                                                      const SizedBox(width: 4),
                                                      const VerifiedBadge(size: 16),
                                                    ],
                                                  ],
                                                ),
                                                if (employerEmail.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    employerEmail,
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.textTertiary,
                                                      fontSize: 10,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: [
                                                    if (employerCity.isNotEmpty)
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.location_on_outlined,
                                                            size: 12,
                                                            color: AppColors.textTertiary,
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            '$employerCity, $employerCountry',
                                                            style: AppTextStyles.caption.copyWith(
                                                              color: AppColors.textTertiary,
                                                              fontSize: 11,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    if (employerRatingCount > 0)
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.star_rounded,
                                                            size: 13,
                                                            color: Colors.amber,
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            '${employerRating.toStringAsFixed(1)} ($employerRatingCount)',
                                                            style: AppTextStyles.caption.copyWith(
                                                              color: AppColors.textSecondary,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Arrow indicator
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppColors.textTertiary,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                      ),
                                    );
                                  }
                                }
                                
                                // Show error state if data couldn't be loaded
                                if (ownerSnapshot.hasError) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: AppColors.shadowSoft,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Error al cargar información del empleador',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return const SizedBox.shrink();
                              },
                            ),

                            const SizedBox(height: 20),

                            // Pill-style Tabs
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: AppColors.shadowSoft,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: AppColors.textSecondary,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: 'Resumen'),
                                  Tab(text: 'Detalles'),
                                  Tab(text: 'Requisitos'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tab Content
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(description, dateText, applicantsIds.length, jobData),
                            _buildDetailsTab(duration, city, country, createdAt),
                            _buildRequirementsTab(requirements),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Button
          bottomNavigationBar: _buildBottomBar(
            context,
            jobData,
            isOwner,
            hasApplied,
            isHired,
            status,
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'open':
        bgColor = AppColors.chipGreen;
        textColor = AppColors.chipGreenText;
        label = 'Abierto';
        break;
      case 'assigned':
        bgColor = AppColors.chipOrange;
        textColor = AppColors.chipOrangeText;
        label = 'Asignado';
        break;
      case 'closed':
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = 'Cerrado';
        break;
      default:
        bgColor = AppColors.chipBlue;
        textColor = AppColors.chipBlueText;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOverviewTab(String description, String dateText, int applicantsCount, Map<String, dynamic> jobData) {
    final totalSlots = jobData['totalSlots'] ?? 1;
    final filledSlots = jobData['filledSlots'] ?? 0;
    final isClosed = jobData['isClosed'] ?? false;
    final remainingSlots = totalSlots - filledSlots;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slots indicator
          if (totalSlots > 1 || filledSlots > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isClosed
                    ? LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      )
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.shadowSoft,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isClosed ? 'Cupos completos' : 'Cupos disponibles',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isClosed
                              ? 'Ya no se aceptan más postulaciones'
                              : remainingSlots == 1
                                  ? '¡Queda 1 cupo!'
                                  : 'Quedan $remainingSlots de $totalSlots cupos',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$filledSlots / $totalSlots',
                      style: AppTextStyles.h5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Descripción', style: AppTextStyles.h6),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '$applicantsCount',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Postulantes',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: AppColors.secondary, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        dateText.split(' ').last,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Publicado',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(String duration, String city, String country, Timestamp? createdAt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildDetailItem(Icons.schedule_outlined, 'Duración', duration),
          _buildDetailItem(Icons.location_on_outlined, 'Ubicación', '$city, $country'),
          if (createdAt != null)
            _buildDetailItem(
              Icons.event_outlined,
              'Fecha de publicación',
              DateFormat('dd MMMM yyyy').format(createdAt.toDate()),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsTab(String requirements) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Requisitos', style: AppTextStyles.h6),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              requirements,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Map<String, dynamic> jobData,
    bool isOwner,
    bool hasApplied,
    bool isHired,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildActionButton(context, jobData, isOwner, hasApplied, isHired, status),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    Map<String, dynamic> jobData,
    bool isOwner,
    bool hasApplied,
    bool isHired,
    String status,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ownerId = jobData['ownerId'] ?? '';
    final hiredCandidate = jobData['hiredCandidate'] as Map<String, dynamic>?;
    final hiredUserId = hiredCandidate?['uid'];

    // Show rating button if job is closed and user is involved
    if (status == 'closed' && currentUser != null) {
      // Owner can rate hired candidate
      if (isOwner && hiredUserId != null) {
        return FutureBuilder<bool>(
          future: RatingService.instance.canRate(widget.jobId, hiredUserId),
          builder: (context, snapshot) {
            final canRate = snapshot.data ?? false;
            if (canRate) {
              final hiredName = hiredCandidate?['name'] ?? 'Usuario';
              return AppPrimaryButton(
                text: 'Calificar a $hiredName',
                icon: Icons.star_rounded,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RateUserScreen(
                        jobId: widget.jobId,
                        userId: hiredUserId,
                        userName: hiredName,
                        jobTitle: jobData['title'] ?? 'Trabajo',
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
              );
            }
            return Row(
              children: [
                Expanded(
                  child: AppPrimaryButton(
                    text: 'Postulantes',
                    icon: Icons.people_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ApplicantsListScreen(jobId: widget.jobId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      }
      
      // Hired candidate can rate owner (as employer)
      if (isHired) {
        return FutureBuilder<bool>(
          future: EmployerReviewService.instance.hasWorkerReviewedEmployer(
            currentUser.uid,
            ownerId,
            widget.jobId,
          ),
          builder: (context, snapshot) {
            final hasReviewed = snapshot.data ?? false;
            if (!hasReviewed) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                builder: (context, ownerSnapshot) {
                  final ownerName = ownerSnapshot.data?.get('fullName') ?? 'Usuario';
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
                    builder: (context, currentUserSnapshot) {
                      final currentUserName = currentUserSnapshot.data?.get('fullName') ?? 'Usuario';
                      return AppPrimaryButton(
                        text: 'Calificar al Empleador',
                        icon: Icons.star_rounded,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateEmployerScreen(
                                employerId: ownerId,
                                employerName: ownerName,
                                jobId: widget.jobId,
                                jobTitle: jobData['title'] ?? 'Trabajo',
                                workerId: currentUser.uid,
                                workerName: currentUserName,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                      );
                    },
                  );
                },
              );
            }
            return AppPrimaryButton(
              text: 'Trabajo Completado',
              icon: Icons.check_circle_rounded,
              useGradient: false,
              onPressed: null,
            );
          },
        );
      }
    }

    if (isOwner) {
      final hasHiredCandidate = jobData['hiredCandidate'] != null;
      return Row(
        children: [
          Expanded(
            flex: hasHiredCandidate ? 3 : 1,
            child: AppPrimaryButton(
              text: hasHiredCandidate ? 'Postulantes' : 'Ver Postulantes',
              icon: Icons.people_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicantsListScreen(jobId: widget.jobId),
                  ),
                );
              },
            ),
          ),
          if (hasHiredCandidate) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppPrimaryButton(
                text: 'Chat',
                icon: Icons.chat_rounded,
                useGradient: false,
                onPressed: () => _openChat(context, jobData),
              ),
            ),
          ],
        ],
      );
    }

    if (isHired) {
      return AppPrimaryButton(
        text: 'Ir al Chat',
        icon: Icons.chat_rounded,
        onPressed: () => _openChat(context, jobData),
      );
    }

    // Check application status for current user
    if (hasApplied && currentUser != null) {
      return FutureBuilder<QueryDocumentSnapshot?>(
        future: FirebaseFirestore.instance
            .collection('applications')
            .where('jobId', isEqualTo: widget.jobId)
            .where('userId', isEqualTo: currentUser.uid)
            .limit(1)
            .get()
            .then((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return AppPrimaryButton(
              text: 'Ya te postulaste',
              icon: Icons.check_circle_rounded,
              useGradient: false,
              onPressed: null,
            );
          }

          final applicationData = snapshot.data!.data() as Map<String, dynamic>?;
          if (applicationData == null) {
            return AppPrimaryButton(
              text: 'Ya te postulaste',
              icon: Icons.check_circle_rounded,
              useGradient: false,
              onPressed: null,
            );
          }

          final appStatus = applicationData['status'] ?? 'pending';

          // Handle different application statuses
          switch (appStatus) {
            case 'pending':
              return AppPrimaryButton(
                text: 'Postulación Pendiente',
                icon: Icons.hourglass_empty_rounded,
                useGradient: false,
                onPressed: null,
              );

            case 'accepted':
            case 'assigned':
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appStatus == 'assigned' ? '¡Trabajo Asignado!' : '¡Postulación Aceptada!',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Marcar Completado',
                          icon: Icons.task_alt_rounded,
                          onPressed: () => _requestCompletion(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Chat',
                          icon: Icons.chat_rounded,
                          useGradient: false,
                          onPressed: () => _openChat(context, jobData),
                        ),
                      ),
                    ],
                  ),
                ],
              );

            case 'in_progress':
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pending_actions_rounded, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Trabajo en Progreso',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Marcar Completado',
                          icon: Icons.task_alt_rounded,
                          onPressed: () => _requestCompletion(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Chat',
                          icon: Icons.chat_rounded,
                          useGradient: false,
                          onPressed: () => _openChat(context, jobData),
                        ),
                      ),
                    ],
                  ),
                ],
              );

            case 'waiting_confirmation':
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: Colors.orange.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Esperando Confirmación',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'El empleador debe confirmar la finalización del trabajo',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    text: 'Ir al Chat',
                    icon: Icons.chat_rounded,
                    useGradient: false,
                    onPressed: () => _openChat(context, jobData),
                  ),
                ],
              );

            case 'completed':
              return AppPrimaryButton(
                text: 'Trabajo Completado',
                icon: Icons.check_circle_rounded,
                useGradient: false,
                onPressed: null,
              );

            case 'rejected':
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Postulación Rechazada',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );

            default:
              return AppPrimaryButton(
                text: 'Ya te postulaste',
                icon: Icons.check_circle_rounded,
                useGradient: false,
                onPressed: null,
              );
          }
        },
      );
    }

    if (status != 'open') {
      return AppPrimaryButton(
        text: status == 'assigned' ? 'Trabajo Asignado' : 'Trabajo Cerrado',
        useGradient: false,
        onPressed: null,
      );
    }

    return AppPrimaryButton(
      text: 'Postularme Ahora',
      icon: Icons.send_rounded,
      isLoading: _isApplying,
      onPressed: () => _applyToJob(context, jobData),
    );
  }
}
