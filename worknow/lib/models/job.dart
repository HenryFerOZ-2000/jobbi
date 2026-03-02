import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final String category;
  final double budget;
  final String status;
  final String city;
  final String country;
  final String? province;
  final String ownerId;
  final Timestamp createdAt;
  final List<String> applicantsIds;
  final int totalSlots;
  final int filledSlots;
  final bool isClosed;
  final String? imageUrl;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.status,
    required this.city,
    required this.country,
    this.province,
    required this.ownerId,
    required this.createdAt,
    required this.applicantsIds,
    this.totalSlots = 1,
    this.filledSlots = 0,
    this.isClosed = false,
    this.imageUrl,
  });

  factory Job.fromMap(Map<String, dynamic> map, String id) {
    return Job(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      budget: (map['budget'] ?? 0.0) is int
          ? (map['budget'] as int).toDouble()
          : (map['budget'] ?? 0.0),
      status: map['status'] ?? 'open',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      province: map['province'],
      ownerId: map['ownerId'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      applicantsIds: List<String>.from(map['applicantsIds'] ?? []),
      totalSlots: map['totalSlots'] ?? 1,
      filledSlots: map['filledSlots'] ?? 0,
      isClosed: map['isClosed'] ?? false,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'status': status,
      'city': city,
      'country': country,
      if (province != null) 'province': province,
      'ownerId': ownerId,
      'createdAt': createdAt,
      'applicantsIds': applicantsIds,
      'totalSlots': totalSlots,
      'filledSlots': filledSlots,
      'isClosed': isClosed,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Check if has available slots
  bool get hasAvailableSlots => filledSlots < totalSlots && !isClosed;

  /// Get remaining slots
  int get remainingSlots => totalSlots - filledSlots;

  /// Get slots progress (0.0 to 1.0)
  double get slotsProgress => totalSlots > 0 ? filledSlots / totalSlots : 0.0;
}

