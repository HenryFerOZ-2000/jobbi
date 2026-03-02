import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../controllers/applicants_controller.dart';
import '../../controllers/job_status_controller.dart';
import '../../widgets/verified_badge.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';

class ApplicantsListScreen extends StatefulWidget {
  final String jobId;

  const ApplicantsListScreen({super.key, required this.jobId});

  @override
  State<ApplicantsListScreen> createState() => _ApplicantsListScreenState();
}

class _ApplicantsListScreenState extends State<ApplicantsListScreen> {
  final ApplicantsController _controller = ApplicantsController.instance;
  String _selectedFilter = 'all'; // all, pending, accepted, rejected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Postulantes',
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Slots Info Banner
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get(),
            builder: (context, jobSnapshot) {
              if (!jobSnapshot.hasData) return const SizedBox.shrink();
              
              final jobData = jobSnapshot.data!.data() as Map<String, dynamic>?;
              if (jobData == null) return const SizedBox.shrink();

              final totalSlots = jobData['totalSlots'] ?? 1;
              final filledSlots = jobData['filledSlots'] ?? 0;
              final isClosed = jobData['isClosed'] ?? false;
              final remainingSlots = totalSlots - filledSlots;
              final progress = totalSlots > 0 ? filledSlots / totalSlots : 0.0;

              return Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isClosed
                      ? LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                        )
                      : LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.shadowMedium,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.people_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Cupos',
                              style: AppTextStyles.h6.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
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
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isClosed ? Colors.red.shade200 : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isClosed
                          ? '🔒 Cupos completos'
                          : remainingSlots == 1
                              ? '¡Queda 1 cupo disponible!'
                              : 'Quedan $remainingSlots cupos disponibles',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Stats and Filters
          FutureBuilder<Map<String, int>>(
            future: _controller.getApplicantsStats(widget.jobId),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {
                'total': 0,
                'pending': 0,
                'accepted': 0,
                'rejected': 0,
              };

              return Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.shadowSoft,
                ),
                child: Column(
                  children: [
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Total',
                          stats['total']!,
                          AppColors.primary,
                        ),
                        _buildStatItem(
                          'Pendientes',
                          stats['pending']!,
                          AppColors.warning,
                        ),
                        _buildStatItem(
                          'Aceptados',
                          stats['accepted']!,
                          AppColors.success,
                        ),
                        _buildStatItem(
                          'Rechazados',
                          stats['rejected']!,
                          AppColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'Todos'),
                          const SizedBox(width: 8),
                          _buildFilterChip('pending', 'Pendientes'),
                          const SizedBox(width: 8),
                          _buildFilterChip('accepted', 'Aceptados'),
                          const SizedBox(width: 8),
                          _buildFilterChip('rejected', 'Rechazados'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Applicants List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _controller.getApplicants(widget.jobId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text('Error al cargar postulantes', style: AppTextStyles.h6),
                      ],
                    ),
                  );
                }

                var applicants = snapshot.data ?? [];

                // Apply filter
                if (_selectedFilter != 'all') {
                  applicants = applicants
                      .where((a) => a['status'] == _selectedFilter)
                      .toList();
                }

                if (applicants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 80,
                          color: AppColors.textSoft.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _selectedFilter == 'all'
                              ? 'Aún no hay postulantes'
                              : 'No hay postulantes $_selectedFilter',
                          style: AppTextStyles.h5.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los postulantes aparecerán aquí cuando alguien aplique',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSoft,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: applicants.length,
                  itemBuilder: (context, index) {
                    final applicant = applicants[index];
                    return _buildApplicantCard(context, applicant);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTextStyles.h4.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildApplicantCard(BuildContext context, Map<String, dynamic> applicant) {
    final userName = applicant['userName'] ?? 'Usuario';
    // final userEmail = applicant['userEmail'] ?? ''; // Not used in UI
    final userCategory = applicant['userCategory'] ?? 'Sin categoría';
    final userRating = applicant['userRating'] ?? 0.0;
    final userVerified = applicant['userVerified'] ?? false;
    final status = applicant['status'] ?? 'pending';
    final message = applicant['message'] ?? '';
    final appliedAt = applicant['appliedAt'] as Timestamp?;
    final userId = applicant['userId'] ?? '';

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = appliedAt != null
        ? dateFormat.format(appliedAt.toDate())
        : 'Fecha desconocida';

    // Status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
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
        statusText = status;
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, Status
            Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: userId),
                      ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: AppTextStyles.h4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: AppTextStyles.h6.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (userVerified) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userCategory,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (userRating > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userRating.toStringAsFixed(1),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Status Badge
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

            // Message if provided
            if (message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mensaje:',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Date and Email
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                // Chat Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(context, userId),
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
                const SizedBox(width: 12),

                // Accept/Reject/Assign buttons based on status
                if (status == 'pending') ...[
                  Expanded(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get(),
                      builder: (context, jobSnapshot) {
                        bool canAccept = true;
                        if (jobSnapshot.hasData) {
                          final jobData = jobSnapshot.data!.data() as Map<String, dynamic>?;
                          if (jobData != null) {
                            final totalSlots = jobData['totalSlots'] ?? 1;
                            final filledSlots = jobData['filledSlots'] ?? 0;
                            final isClosed = jobData['isClosed'] ?? false;
                            canAccept = filledSlots < totalSlots && !isClosed;
                          }
                        }

                        return ElevatedButton.icon(
                          onPressed: canAccept ? () => _acceptApplicant(context, userId, userName) : null,
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text(canAccept ? 'Aceptar' : 'Sin cupos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAccept ? AppColors.success : Colors.grey,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _rejectApplicant(context, userId, userName),
                    icon: const Icon(Icons.cancel_outlined),
                    color: AppColors.error,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ] else if (status == 'accepted' || status == 'assigned' || status == 'in_progress') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: Icon(
                        status == 'in_progress' ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                        size: 18,
                      ),
                      label: Text(
                        status == 'in_progress' ? 'En Progreso' : 
                        status == 'assigned' ? 'Asignado' : 'Aceptado'
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else if (status == 'waiting_confirmation') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmCompletion(context, userId, userName),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else if (status == 'completed') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.task_alt_rounded, size: 18),
                      label: const Text('Completado'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptApplicant(BuildContext context, String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Aceptar postulante')),
          ],
        ),
        content: Text('¿Deseas aceptar a $userName? Se le notificará de inmediato.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _controller.acceptApplicant(jobId: widget.jobId, userId: userId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName ha sido aceptado'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectApplicant(BuildContext context, String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Rechazar postulante')),
          ],
        ),
        content: Text('¿Estás seguro de rechazar a $userName? Esta acción se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _controller.rejectApplicant(jobId: widget.jobId, userId: userId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName ha sido rechazado'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmCompletion(BuildContext context, String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Confirmar finalización')),
          ],
        ),
        content: Text(
          '$userName ha solicitado marcar este trabajo como completado. '
          '¿Confirmas que el trabajo fue finalizado satisfactoriamente?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final statusController = JobStatusController.instance;
      await statusController.confirmCompletion(jobId: widget.jobId, userId: userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Trabajo completado por $userName confirmado'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openChat(BuildContext context, String userId) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final chatId = await _controller.openChat(
        jobId: widget.jobId,
        userId: userId,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Get job and user data for chat screen
        final jobDoc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .get();
        final jobData = jobDoc.data();
        final jobTitle = jobData?['title'] ?? 'Trabajo';

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final userData = userDoc.data();
        final userName = userData?['fullName'] ?? userData?['name'] ?? 'Usuario';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserName: userName,
              jobTitle: jobTitle,
              showBackButton: true,
                        ),
                ),
              );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
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
