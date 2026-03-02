import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../profile/profile_screen.dart';
import '../../controllers/saved_profiles_controller.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  String _sortBy = 'rating'; // rating, name, recent

  final List<String> _categories = [
    'Todos',
    'Desarrollo y Tecnología',
    'Diseño y Creatividad',
    'Redacción y Traducción',
    'Marketing Digital',
    'Administración',
    'Construcción',
    'Servicios del Hogar',
    'Transporte',
    'Educación',
    'Salud',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize saved profiles
    SavedProfilesController.instance.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          'Buscar Profesionales',
          style: AppTextStyles.h5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSearchBar(),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              color: AppColors.scaffoldBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Sort options
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Ordenar por:',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            _buildSortChip('rating', '⭐ Calificación'),
                            _buildSortChip('name', '📝 Nombre'),
                            _buildSortChip('recent', '🆕 Recientes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Results
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
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
                          Text('Error al cargar usuarios', style: AppTextStyles.h5),
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
                            Icons.people_alt_outlined,
                            size: 80,
                            color: AppColors.textSoft.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No se encontraron usuarios',
                            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otros filtros o busca por nombre',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSoft),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              var users = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
                final category = (data['category'] ?? '').toString().toLowerCase();
                final skillsData = data['skills'] ?? data['habilidades'];
                List<String> skills = [];
                if (skillsData is List) {
                  skills = skillsData.map((e) => e.toString().toLowerCase()).toList();
                } else if (skillsData is String && skillsData.isNotEmpty) {
                  skills = skillsData.split(',').map((s) => s.trim().toLowerCase()).toList();
                }

                // Category filter
                if (_selectedCategory != 'Todos' && category != _selectedCategory.toLowerCase()) {
                  return false;
                }

                // Search filter
                if (_searchQuery.isNotEmpty) {
                  return name.contains(_searchQuery) ||
                      category.contains(_searchQuery) ||
                      skills.any((skill) => skill.contains(_searchQuery));
                }

                return true;
              }).toList();

              // Sort users
              users.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;

                switch (_sortBy) {
                  case 'rating':
                    final aRating = (aData['rating'] ?? 0.0) is int
                        ? (aData['rating'] as int).toDouble()
                        : (aData['rating'] ?? 0.0);
                    final bRating = (bData['rating'] ?? 0.0) is int
                        ? (bData['rating'] as int).toDouble()
                        : (bData['rating'] ?? 0.0);
                    return bRating.compareTo(aRating); // Descending
                  case 'name':
                    final aName = (aData['fullName'] ?? aData['name'] ?? '').toString().toLowerCase();
                    final bName = (bData['fullName'] ?? bData['name'] ?? '').toString().toLowerCase();
                    return aName.compareTo(bName); // Ascending
                  case 'recent':
                    final aCreatedAt = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
                    final bCreatedAt = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
                    return bCreatedAt.compareTo(aCreatedAt); // Descending
                  default:
                    return 0;
                }
              });

              if (users.isEmpty) {
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
                          Text('No se encontraron resultados', style: AppTextStyles.h6),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otros filtros o busca por nombre',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSoft),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final userDoc = users[index];
                      final userData = userDoc.data() as Map<String, dynamic>;
                      return _buildUserCard(context, userDoc.id, userData);
                    },
                    childCount: users.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSoft,
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o habilidades...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSoft,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
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
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildSortChip(String value, String label) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _sortBy = value;
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
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String userId, Map<String, dynamic> userData) {
    // Get name from any possible field
    String name = userData['fullName'] ?? userData['name'] ?? '';
    if (name.isEmpty) {
      final nombre = userData['nombre'] ?? '';
      final apellido = userData['apellido'] ?? '';
      name = '$nombre $apellido'.trim();
    }
    if (name.isEmpty) {
      name = 'Usuario';
    }

    final category = userData['category'] ?? 'Sin categoría';
    final city = userData['ciudad'] ?? userData['city'] ?? '';
    final country = userData['pais'] ?? userData['country'] ?? '';
    final rating = (userData['rating'] ?? 0.0) is int
        ? (userData['rating'] as int).toDouble()
        : (userData['rating'] ?? 0.0).toDouble();
    final totalRatings = userData['totalRatings'] ?? 0;

    // Get skills
    List<String> skills = [];
    final skillsData = userData['skills'] ?? userData['habilidades'];
    if (skillsData is List) {
      skills = skillsData.map((e) => e.toString()).take(3).toList();
    } else if (skillsData is String && skillsData.isNotEmpty) {
      skills = skillsData
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(3)
          .toList();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: userId),
          ),
        );
      },
      child: Container(
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
          child: Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: AppTextStyles.h6.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Category
                    Text(
                      category,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Location and Rating
                    Row(
                      children: [
                        if (city.isNotEmpty || country.isNotEmpty) ...[
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              [city, country].where((s) => s.isNotEmpty).join(', '),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (totalRatings > 0) const SizedBox(width: 8),
                        ],
                        if (totalRatings > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$rating ($totalRatings)',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              skill,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Save button
              AnimatedBuilder(
                animation: SavedProfilesController.instance,
                builder: (context, _) {
                  final isSaved = SavedProfilesController.instance.isProfileSaved(userId);
                  return IconButton(
                    onPressed: () async {
                      await SavedProfilesController.instance.toggleSavedProfile(
                        userId: userId,
                        userData: userData,
                      );
                    },
                    icon: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: isSaved ? AppColors.primary : AppColors.textTertiary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

