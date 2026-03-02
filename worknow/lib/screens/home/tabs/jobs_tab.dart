import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../services/favorites_service.dart';
import '../../../controllers/posted_jobs_controller.dart';
import '../../jobs/create_job_screen.dart';
import '../../jobs/job_details_screen.dart';
import '../../../services/notification_service.dart';
import '../../notifications/notifications_screen.dart';
import '../../users/users_list_screen.dart';
import '../../chat/chats_list_screen.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      
      // Mostrar búsqueda flotante cuando se hace scroll más de 200px
      if (offset > 200 && !_showFloatingSearch) {
        setState(() {
          _showFloatingSearch = true;
        });
      } else if (offset <= 200 && _showFloatingSearch) {
        setState(() {
          _showFloatingSearch = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header con AppBar
              SliverAppBar(
                backgroundColor: AppColors.scaffoldBackground,
                elevation: 0,
                expandedHeight: 230,
                floating: false,
                pinned: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: AppColors.scaffoldBackground,
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Action Icons Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Explorar',
                                      style: AppTextStyles.h2.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Action Icons
                              Row(
                                children: [
                                  // Notification bell with badge
                                  StreamBuilder<int>(
                                    stream: NotificationService.instance.getUnreadCountStream(),
                                    builder: (context, snapshot) {
                                      final unreadCount = snapshot.data ?? 0;
                                      
                                      return InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const NotificationsScreen(),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              const Icon(
                                                Icons.notifications_outlined,
                                                color: AppColors.textSecondary,
                                                size: 24,
                                              ),
                                              if (unreadCount > 0)
                                                Positioned(
                                                  top: -4,
                                                  right: -4,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.error,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    constraints: const BoxConstraints(
                                                      minWidth: 18,
                                                      minHeight: 18,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  // Users Button
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const UsersListScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.people_outline_rounded,
                                        color: AppColors.textSecondary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  // Messages Button
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ChatsListScreen(showBackButton: true),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: AppColors.textSecondary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Encuentra el trabajo perfecto para ti',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Search Bar
                        _buildSearchBar(),
                      ],
                    ),
                  ),
                ),
              ),

          // Filter Tabs
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              color: AppColors.scaffoldBackground,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterTab('Todos'),
                    const SizedBox(width: 16),
                    _buildFilterTab('open'),
                    const SizedBox(width: 16),
                    _buildFilterTab('assigned'),
                    const SizedBox(width: 16),
                    _buildFilterTab('closed'),
                  ],
                ),
              ),
            ),
          ),

          // Jobs List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar trabajos',
                            style: AppTextStyles.h5,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_outline_rounded,
                            size: 80,
                            color: AppColors.textSoft.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No hay trabajos disponibles',
                            style: AppTextStyles.h5.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¡Sé el primero en publicar!',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              var jobs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'open';
                final title = (data['title'] ?? '').toString().toLowerCase();
                final category = (data['category'] ?? '').toString().toLowerCase();

                // Apply filters
                if (_selectedFilter != 'Todos' && status != _selectedFilter) {
                  return false;
                }

                // Apply search
                if (_searchQuery.isNotEmpty) {
                  return title.contains(_searchQuery) || category.contains(_searchQuery);
                }

                return true;
              }).toList();

              if (jobs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: AppColors.textSoft.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron resultados',
                            style: AppTextStyles.h6,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otros filtros',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = jobs[index];
                      final jobData = job.data() as Map<String, dynamic>;
                      return _buildModernJobCard(context, job.id, jobData);
                    },
                    childCount: jobs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // Floating Search Bar (aparece al hacer scroll)
      AnimatedPositioned(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        top: _showFloatingSearch ? 0 : -100,
        left: 0,
        right: 0,
        child: IgnorePointer(
          ignoring: !_showFloatingSearch,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            opacity: _showFloatingSearch ? 1.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                boxShadow: _showFloatingSearch
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: _buildSearchBar(),
                ),
              ),
            ),
          ),
        ),
      ),

      // Floating Action Button
      Positioned(
        bottom: 90,
        right: 24,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateJobScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              'Publicar',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    ],
   ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar trabajos...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSoft,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilterTab(String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Column(
        children: [
          Text(
            _getFilterLabel(filter),
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 20,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'Todos':
        return 'Todos';
      case 'open':
        return 'Abiertos';
      case 'assigned':
        return 'Asignados';
      case 'closed':
        return 'Cerrados';
      default:
        return filter;
    }
  }

  Widget _buildModernJobCard(BuildContext context, String jobId, Map<String, dynamic> jobData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final title = jobData['title'] ?? 'Sin título';
    final city = jobData['city'] ?? 'Ciudad';
    final country = jobData['country'] ?? 'País';
    final budget = jobData['budget'] ?? 0;
    final status = jobData['status'] ?? 'open';
    final category = jobData['category'] ?? 'General';
    final applicantsIds = List<String>.from(jobData['applicantsIds'] ?? []);
    final createdAt = jobData['createdAt'] as Timestamp?;
    final ownerId = jobData['ownerId'] ?? '';
    final isOwner = currentUserId != null && currentUserId == ownerId;

    // Calculate time ago
    String timeAgo = 'Nuevo';
    if (createdAt != null) {
      final now = DateTime.now();
      final date = createdAt.toDate();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        timeAgo = 'Hace ${difference.inDays}d';
      } else if (difference.inHours > 0) {
        timeAgo = 'Hace ${difference.inHours}h';
      } else {
        timeAgo = 'Nuevo';
      }
    }

    // Status colors
    Color statusColor = AppColors.chipGreen;
    Color statusTextColor = AppColors.chipGreenText;
    String statusLabel = 'Abierto';

    if (status == 'assigned') {
      statusColor = AppColors.chipOrange;
      statusTextColor = AppColors.chipOrangeText;
      statusLabel = 'Asignado';
    } else if (status == 'closed') {
      statusColor = Colors.grey[200]!;
      statusTextColor = Colors.grey[700]!;
      statusLabel = 'Cerrado';
    }

    // Category icon
    IconData categoryIcon = Icons.work_outline_rounded;
    if (category.toLowerCase().contains('diseñ')) {
      categoryIcon = Icons.palette_outlined;
    } else if (category.toLowerCase().contains('desarroll')) {
      categoryIcon = Icons.code_outlined;
    } else if (category.toLowerCase().contains('market')) {
      categoryIcon = Icons.campaign_outlined;
    } else if (category.toLowerCase().contains('escrit') || category.toLowerCase().contains('redacc')) {
      categoryIcon = Icons.edit_outlined;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailsScreen(jobId: jobId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with favorite button and badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: jobData['imageUrl'] != null && (jobData['imageUrl'] as String).isNotEmpty
                        ? Image.network(
                            jobData['imageUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppColors.scaffoldBackground,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.12),
                                      AppColors.secondary.withValues(alpha: 0.06),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    categoryIcon,
                                    size: 64,
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.12),
                                  AppColors.secondary.withValues(alpha: 0.06),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                categoryIcon,
                                size: 64,
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                  ),
                ),
                
                // Time ago badge (top left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons (top right) - Favorite or Delete
                Positioned(
                  top: 12,
                  right: 12,
                  child: isOwner
                      ? GestureDetector(
                          onTap: () => _showDeleteJobDialog(context, jobId, title),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                          ),
                        )
                      : AnimatedBuilder(
                          animation: FavoritesService.instance,
                          builder: (context, _) {
                            final isFavorite = FavoritesService.instance.isFavorite(jobId);
                            return GestureDetector(
                              onTap: () async {
                                await FavoritesService.instance.toggleFavorite(
                                  jobId: jobId,
                                  jobData: jobData,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isFavorite 
                                          ? 'Eliminado de favoritos'
                                          : 'Agregado a favoritos',
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: AppColors.textSecondary,
                                    ),
                                  );
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite 
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                  color: isFavorite 
                                    ? Colors.redAccent
                                    : AppColors.textTertiary,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIcon,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: AppTextStyles.h6.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Employer Rating
                  if (ownerId.isNotEmpty)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                      builder: (context, ownerSnapshot) {
                        if (ownerSnapshot.hasData && ownerSnapshot.data != null) {
                          final ownerData = ownerSnapshot.data!.data() as Map<String, dynamic>?;
                          if (ownerData != null) {
                            final employerRating = (ownerData['employerRatingAverage'] ?? 0.0) is int 
                                ? (ownerData['employerRatingAverage'] as int).toDouble()
                                : (ownerData['employerRatingAverage'] ?? 0.0);
                            final employerRatingCount = ownerData['employerRatingCount'] ?? 0;
                            
                            if (employerRatingCount > 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      size: 12,
                                      color: AppColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      employerRating.toStringAsFixed(1),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      ' ($employerRatingCount)',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$city, $country',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Divider
                  Container(
                    height: 1,
                    color: AppColors.scaffoldBackground,
                  ),

                  const SizedBox(height: 12),

                  // Bottom row: Budget, Applicants, Status
                  Row(
                    children: [
                      // Budget
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '\$${budget.toStringAsFixed(0)}',
                                style: AppTextStyles.h6.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: '/job',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Applicants count
                      if (applicantsIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${applicantsIds.length}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(width: 8),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showDeleteJobDialog(BuildContext context, String jobId, String title) {
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
                color: Colors.redAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Eliminar trabajo?',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "$title"?\n\nEsta acción no se puede deshacer y el trabajo dejará de aparecer en el feed.',
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
                        Text('Eliminando trabajo...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );

                final success = await PostedJobsController.instance.deleteJob(jobId);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            success ? Icons.check_circle : Icons.error,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            success
                                ? 'Trabajo eliminado correctamente'
                                : 'Error al eliminar el trabajo',
                          ),
                        ],
                      ),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
