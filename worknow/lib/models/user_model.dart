import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String country;
  final String? province;
  final String city;

  final bool hasDegree;
  final String? professionalTitle;
  final String? education;

  final String category;
  final List<String> skills;
  final String experience;
  final List<String>? portfolioLinks;

  final String? notificationToken;
  final double rating;
  final int totalRatings;
  
  // Employer rating (when user acts as employer)
  final double employerRatingAverage;
  final int employerRatingCount;

  // Identity verification fields
  final String verificationStatus; // unverified, pending, verified, rejected
  final String? idCardUrl; // URL foto de cédula
  final String? selfieUrl; // URL selfie
  final Timestamp? submittedAt;
  final Timestamp? verifiedAt;
  final String? rejectionReason;

  final Timestamp createdAt;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.country,
    this.province,
    required this.city,
    required this.hasDegree,
    this.professionalTitle,
    this.education,
    required this.category,
    required this.skills,
    required this.experience,
    this.portfolioLinks,
    this.notificationToken,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.employerRatingAverage = 0.0,
    this.employerRatingCount = 0,
    this.verificationStatus = 'unverified',
    this.idCardUrl,
    this.selfieUrl,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  // Convert from Firestore Map
  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    // Parse skills safely
    List<String> skillsList = [];
    if (map['skills'] != null) {
      if (map['skills'] is List) {
        skillsList = (map['skills'] as List)
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (map['skills'] is String) {
        skillsList = (map['skills'] as String)
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    // Parse portfolio links safely
    List<String>? portfolioList;
    if (map['portfolioLinks'] != null) {
      if (map['portfolioLinks'] is List) {
        portfolioList = (map['portfolioLinks'] as List)
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (map['portfolioLinks'] is String) {
        portfolioList = (map['portfolioLinks'] as String)
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    return AppUser(
      uid: uid,
      fullName: map['fullName'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      country: map['country'] ?? '',
      province: map['province'],
      city: map['city'] ?? '',
      hasDegree: map['hasDegree'] ?? false,
      professionalTitle: map['professionalTitle'],
      education: map['education'] is String ? map['education'] : null,
      category: map['category'] ?? 'Otro',
      skills: skillsList,
      experience: map['experience'] is String ? map['experience'] : '',
      portfolioLinks: portfolioList,
      notificationToken: map['notificationToken'],
      rating: (map['rating'] ?? 0.0) is int ? (map['rating'] as int).toDouble() : (map['rating'] ?? 0.0),
      totalRatings: map['totalRatings'] ?? 0,
      employerRatingAverage: (map['employerRatingAverage'] ?? 0.0) is int ? (map['employerRatingAverage'] as int).toDouble() : (map['employerRatingAverage'] ?? 0.0),
      employerRatingCount: map['employerRatingCount'] ?? 0,
      verificationStatus: map['verificationStatus'] ?? 'unverified',
      idCardUrl: map['idCardUrl'] as String?,
      selfieUrl: map['selfieUrl'] as String?,
      submittedAt: map['submittedAt'] as Timestamp?,
      verifiedAt: map['verifiedAt'] as Timestamp?,
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  // Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'country': country,
      'province': province,
      'city': city,
      'hasDegree': hasDegree,
      'professionalTitle': professionalTitle,
      'education': education,
      'category': category,
      'skills': skills,
      'experience': experience,
      'portfolioLinks': portfolioLinks,
      'notificationToken': notificationToken,
      'rating': rating,
      'totalRatings': totalRatings,
      'employerRatingAverage': employerRatingAverage,
      'employerRatingCount': employerRatingCount,
      'verificationStatus': verificationStatus,
      'idCardUrl': idCardUrl,
      'selfieUrl': selfieUrl,
      'submittedAt': submittedAt,
      'verifiedAt': verifiedAt,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
    };
  }

  // Copy with method for updates
  AppUser copyWith({
    String? fullName,
    String? phone,
    String? country,
    String? province,
    String? city,
    bool? hasDegree,
    String? professionalTitle,
    String? education,
    String? category,
    List<String>? skills,
    String? experience,
    List<String>? portfolioLinks,
    String? notificationToken,
    double? rating,
    int? totalRatings,
    double? employerRatingAverage,
    int? employerRatingCount,
    String? verificationStatus,
    String? idCardUrl,
    String? selfieUrl,
    Timestamp? submittedAt,
    Timestamp? verifiedAt,
    String? rejectionReason,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      hasDegree: hasDegree ?? this.hasDegree,
      professionalTitle: professionalTitle ?? this.professionalTitle,
      education: education ?? this.education,
      category: category ?? this.category,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      notificationToken: notificationToken ?? this.notificationToken,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      employerRatingAverage: employerRatingAverage ?? this.employerRatingAverage,
      employerRatingCount: employerRatingCount ?? this.employerRatingCount,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
    );
  }
  
  // Helper methods for verification status
  bool get isUnverified => verificationStatus == 'unverified';
  bool get isPending => verificationStatus == 'pending';
  bool get isVerified => verificationStatus == 'verified';
  bool get isRejected => verificationStatus == 'rejected';
  bool get canPerformActions => isVerified;
}

