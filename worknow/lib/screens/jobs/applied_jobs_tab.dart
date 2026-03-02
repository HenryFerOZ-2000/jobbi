import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../controllers/applied_jobs_controller.dart';
import '../../services/chat_service.dart';
import 'job_details_screen.dart';
import '../chat/chat_screen.dart';

class AppliedJobsTab extends StatefulWidget {
  const AppliedJobsTab({super.key});

  @override
  State<AppliedJobsTab> createState() => _AppliedJobsTabState();
}

class _AppliedJobsTabState extends State<AppliedJobsTab> {
  final AppliedJobsController _controller = AppliedJobsController.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = 'all'; // all, pending, active, completed

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(
        child: Text('Inicia sesión para ver tus postulaciones.'),
      );
    }

    return Column(
      children: [
        // Filter chips
        Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Todos'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pendientes'),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Activos'),
                const SizedBox(width: 8),
                _buildFilterChip('waiting', 'En Espera'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completados'),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', 'Rechazados'),
              ],
            ),
          ),
        ),
        
        // List
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _controller.getJobsIHaveAppliedTo(),
            builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allApplications = snapshot.data ?? [];
        
        // Filter applications based on selected filter
        final applications = _filterApplications(allApplications);

        if (applications.isEmpty && allApplications.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list_off_rounded,
                    size: 80,
                    color: AppColors.textSoft.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No hay aplicaciones en esta categoría',
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (applications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 80,
                    color: AppColors.textSoft.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No has aplicado a ningún trabajo',
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Explora trabajos y encuentra tu próxima oportunidad!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final application = applications[index];
            return _buildApplicationCard(context, application);
          },
        );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryLight,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      elevation: isSelected ? 2 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  List<Map<String, dynamic>> _filterApplications(List<Map<String, dynamic>> applications) {
    if (_selectedFilter == 'all') return applications;

    return applications.where((app) {
      final status = app['applicationStatus'] ?? 'pending';
      
      switch (_selectedFilter) {
        case 'pending':
          return status == 'pending';
        case 'active':
          return status == 'accepted' || status == 'assigned' || status == 'in_progress';
        case 'waiting':
          return status == 'waiting_confirmation';
        case 'completed':
          return status == 'completed';
        case 'rejected':
          return status == 'rejected';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildApplicationCard(
    BuildContext context,
    Map<String, dynamic> application,
  ) {
    final jobTitle = application['jobTitle'] ?? 'Sin título';
    final jobCategory = application['jobCategory'] ?? 'Sin categoría';
    final jobBudget = application['jobBudget'] ?? 0.0;
    final jobCity = application['jobCity'] ?? '';
    final jobCountry = application['jobCountry'] ?? '';
    final applicationStatus = application['applicationStatus'] ?? 'pending';
    final appliedAt = application['appliedAt'] as Timestamp?;
    final jobId = application['jobId'] ?? '';

    final dateFormat = DateFormat('dd/MM/yyyy');
    final formattedDate = appliedAt != null
        ? dateFormat.format(appliedAt.toDate())
        : 'Fecha desconocida';

    // Get status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (applicationStatus) {
      case 'pending':
        statusColor = AppColors.warning;
        statusText = 'Pendiente';
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case 'accepted':
        statusColor = AppColors.success;
        statusText = 'Aceptado';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'assigned':
        statusColor = AppColors.primary;
        statusText = 'Asignado';
        statusIcon = Icons.assignment_turned_in_rounded;
        break;
      case 'in_progress':
        statusColor = Colors.blue.shade700;
        statusText = 'En Progreso';
        statusIcon = Icons.pending_actions_rounded;
        break;
      case 'waiting_confirmation':
        statusColor = Colors.orange.shade700;
        statusText = 'Esperando Confirmación';
        statusIcon = Icons.schedule_rounded;
        break;
      case 'completed':
        statusColor = Colors.green.shade700;
        statusText = 'Completado';
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusText = 'Rechazado';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.textTertiary;
        statusText = applicationStatus;
        statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailsScreen(jobId: jobId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      jobTitle,
                      style: AppTextStyles.h6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: AppTextStyles.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category and Budget
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      jobCategory,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.attach_money_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  Text(
                    '\$${jobBudget.toStringAsFixed(0)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location and Applied Date
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$jobCity, $jobCountry',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Aplicado: $formattedDate',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              
              // Action buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  // Chat button (available for all except rejected)
                  if (applicationStatus != 'rejected') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openChat(context, application),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Withdraw button (only for pending)
                  if (applicationStatus == 'pending') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showWithdrawDialog(context, jobId, jobTitle),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Retirar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Ver detalles button for accepted/assigned/in_progress
                  if (applicationStatus == 'accepted' || 
                      applicationStatus == 'assigned' || 
                      applicationStatus == 'in_progress') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailsScreen(jobId: jobId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: const Text('Ver Detalles'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Show status info for waiting_confirmation
                  if (applicationStatus == 'waiting_confirmation') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Esperando confirmación',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Show completed status
                  if (applicationStatus == 'completed') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 18,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Completado',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Show rejected status
                  if (applicationStatus == 'rejected') ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Rechazado',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, String jobId, String jobTitle) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Retirar postulación?',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas retirar tu postulación para "$jobTitle"?\n\nPodrás volver a aplicar más tarde si cambias de opinión.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Retirando postulación...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );

                try {
                  await _controller.withdrawApplication(jobId);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text('Postulación retirada correctamente'),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.white,
                              size: 20,
                            ),
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
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retirar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openChat(BuildContext context, Map<String, dynamic> application) async {
    try {
      final jobId = application['jobId'] ?? '';
      final employerId = application['ownerId'] ?? '';
      final jobTitle = application['jobTitle'] ?? 'Trabajo';

      if (jobId.isEmpty || employerId.isEmpty) {
        throw 'Información del trabajo no disponible';
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      // Create or get existing chat
      final chatId = await ChatService.instance.createChat(
        otherUserId: employerId,
        jobId: jobId,
        jobTitle: jobTitle,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Get employer name
        final employerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(employerId)
            .get();
        final employerData = employerDoc.data();
        final employerName = employerData?['fullName'] ?? 
            employerData?['name'] ?? 
            'Empleador';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserName: employerName,
              jobTitle: jobTitle,
              showBackButton: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

