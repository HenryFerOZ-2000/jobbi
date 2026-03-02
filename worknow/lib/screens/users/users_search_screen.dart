import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../profile/profile_screen.dart';

class UsersSearchScreen extends StatefulWidget {
  const UsersSearchScreen({super.key});

  @override
  State<UsersSearchScreen> createState() => _UsersSearchScreenState();
}

class _UsersSearchScreenState extends State<UsersSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  String _sortBy = 'rating'; // rating, name, recent

  final List<String> _categories = [
    'Todos',
    'Desarrollo de Software',
    'Diseño Gráfico',
    'Marketing Digital',
    'Redacción y Contenido',
    'Construcción',
    'Servicios del Hogar',
    'Educación',
    'Salud',
    'Otro',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: AppColors.scaffoldBackground,
            elevation: 0,
            expandedHeight: 210,
            floating: false,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar Profesionales',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Encuentra el profesional perfecto',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    // Search Bar
                    _buildSearchBar(),
                  ],
                ),
              ),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              color: AppColors.scaffoldBackground,
              child: Column(
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
                      child: Text(
                        'Error al cargar usuarios',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
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
                            Icons.people_outline_rounded,
                            size: 80,
                            color: AppColors.textSoft.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No hay usuarios',
                            style: AppTextStyles.h5.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Filter users
              var users = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fullName = (data['fullName'] ?? '').toString().toLowerCase();
                final name = (data['name'] ?? '').toString().toLowerCase();
                final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                final apellido = (data['apellido'] ?? '').toString().toLowerCase();
                final combinedName = '$fullName $name $nombre $apellido'.toLowerCase();
                final category = (data['category'] ?? '').toString();
                
                // Get skills from either 'skills' or 'habilidades'
                List<String> skills = [];
                final skillsData = data['skills'] ?? data['habilidades'];
                if (skillsData is List) {
                  skills = skillsData.map((e) => e.toString().toLowerCase()).toList();
                } else if (skillsData is String && skillsData.isNotEmpty) {
                  skills = skillsData.split(',').map((s) => s.trim().toLowerCase()).toList();
                }

                // Search filter
                if (_searchQuery.isNotEmpty) {
                  final matchesName = combinedName.contains(_searchQuery);
                  final matchesSkills = skills.any((skill) => skill.contains(_searchQuery));
                  if (!matchesName && !matchesSkills) return false;
                }

                // Category filter
                if (_selectedCategory != 'Todos' && category != _selectedCategory) {
                  return false;
                }

                return true;
              }).toList();

              // Sort users
              users.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                if (_sortBy == 'rating') {
                  final ratingA = (dataA['rating'] ?? 0.0) is int 
                      ? (dataA['rating'] as int).toDouble() 
                      : (dataA['rating'] ?? 0.0).toDouble();
                  final ratingB = (dataB['rating'] ?? 0.0) is int 
                      ? (dataB['rating'] as int).toDouble() 
                      : (dataB['rating'] ?? 0.0).toDouble();
                  return ratingB.compareTo(ratingA);
                } else if (_sortBy == 'name') {
                  String nameA = dataA['fullName'] ?? dataA['name'] ?? '';
                  if (nameA.isEmpty) {
                    final nombre = dataA['nombre'] ?? '';
                    final apellido = dataA['apellido'] ?? '';
                    nameA = '$nombre $apellido'.trim();
                  }
                  
                  String nameB = dataB['fullName'] ?? dataB['name'] ?? '';
                  if (nameB.isEmpty) {
                    final nombre = dataB['nombre'] ?? '';
                    final apellido = dataB['apellido'] ?? '';
                    nameB = '$nombre $apellido'.trim();
                  }
                  
                  return nameA.compareTo(nameB);
                } else {
                  // recent
                  final dateA = dataA['createdAt'] as Timestamp?;
                  final dateB = dataB['createdAt'] as Timestamp?;
                  if (dateA != null && dateB != null) {
                    return dateB.compareTo(dateA);
                  }
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
                          Text(
                            'No se encontraron resultados',
                            style: AppTextStyles.h6,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
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
          enabledBorder: OutlineInputBorder(
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
      padding: const EdgeInsets.only(right: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 0,
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
    
    // Get skills (compatible con 'skills' y 'habilidades')
    List<String> skills = [];
    final skillsData = userData['skills'] ?? userData['habilidades'];
    if (skillsData is List) {
      skills = skillsData
          .map((e) => e.toString())
          .take(3)
          .toList();
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
                    ),
                    const SizedBox(height: 8),
                    
                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: rating > 0 ? Colors.amber : Colors.grey[300],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : 'Sin calificaciones',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: rating > 0 ? AppColors.textPrimary : AppColors.textTertiary,
                          ),
                        ),
                        if (totalRatings > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($totalRatings)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Location
                    if (city.isNotEmpty) ...[
                      const SizedBox(height: 6),
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
                              '$city${country.isNotEmpty ? ", $country" : ""}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Skills
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.scaffoldBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              skill,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

