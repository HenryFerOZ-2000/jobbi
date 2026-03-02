import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../job_details_screen.dart';

class MyPublishedJobsTab extends StatelessWidget {
  const MyPublishedJobsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('ownerId', isEqualTo: currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 24),
                Text(
                  'No has publicado trabajos',
                  style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Publica tu primer trabajo',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        final jobs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: jobs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final job = jobs[index];
            final jobData = job.data() as Map<String, dynamic>;
            final title = jobData['title'] ?? 'Sin título';
            final category = jobData['category'] ?? '';
            final city = jobData['city'] ?? '';
            final status = jobData['status'] ?? 'open';
            final budget = jobData['budget'] ?? 0;
            final applicantsIds = List<String>.from(jobData['applicantsIds'] ?? []);
            final createdAt = jobData['createdAt'] as Timestamp?;

            String dateText = '';
            if (createdAt != null) {
              dateText = DateFormat('dd MMM yyyy').format(createdAt.toDate());
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailsScreen(jobId: job.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Title + Status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: AppTextStyles.h5.copyWith(
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
                                color: _getStatusColor(status),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusLabel(status),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Info Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (category.isNotEmpty)
                              _buildInfoChip(
                                Icons.category_outlined,
                                category,
                                AppColors.chipGreen,
                                AppColors.chipGreenText,
                              ),
                            if (city.isNotEmpty)
                              _buildInfoChip(
                                Icons.location_on_outlined,
                                city,
                                AppColors.chipBlue,
                                AppColors.chipBlueText,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        Divider(color: Colors.grey[200], height: 1),
                        const SizedBox(height: 16),

                        // Footer: Budget + Applicants + Date
                        Row(
                          children: [
                            // Budget
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.attach_money,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Presupuesto',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        Text(
                                          '\$${budget.toStringAsFixed(0)}',
                                          style: AppTextStyles.labelLarge.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Applicants
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: applicantsIds.isEmpty
                                    ? Colors.grey[100]
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: applicantsIds.isEmpty
                                      ? Colors.grey[300]!
                                      : AppColors.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 18,
                                    color: applicantsIds.isEmpty
                                        ? Colors.grey[600]
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${applicantsIds.length}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: applicantsIds.isEmpty
                                          ? Colors.grey[600]
                                          : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (dateText.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 13,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Publicado: $dateText',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Abierto';
      case 'assigned':
        return 'Asignado';
      case 'closed':
        return 'Cerrado';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.success;
      case 'assigned':
        return AppColors.warning;
      case 'closed':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}
