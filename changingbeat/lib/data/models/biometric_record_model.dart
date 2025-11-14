/// Modelo de registro biométrico
class BiometricRecordModel {
  final String? id;
  final String documentNumber;
  final String documentType;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String? gender;
  final String? nationality;
  final String? photoBase64;
  final String? faceEmbedding;
  final double? matchScore;
  final String status;
  final String? tabletId;
  final String? operatorId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  BiometricRecordModel({
    this.id,
    required this.documentNumber,
    required this.documentType,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.gender,
    this.nationality,
    this.photoBase64,
    this.faceEmbedding,
    this.matchScore,
    this.status = 'pending',
    this.tabletId,
    this.operatorId,
    DateTime? createdAt,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BiometricRecordModel.fromJson(Map<String, dynamic> json) {
    return BiometricRecordModel(
      id: json['_id'] ?? json['id'] as String?,
      documentNumber: json['documentNumber'] ?? '',
      documentType: json['documentType'] ?? 'CC',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      birthDate:
          json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      gender: json['gender'] as String?,
      nationality: json['nationality'] as String?,
      photoBase64: json['photoBase64'] as String?,
      faceEmbedding: json['faceEmbedding'] as String?,
      matchScore: json['matchScore'] != null
          ? (json['matchScore'] as num).toDouble()
          : null,
      status: json['status'] ?? 'pending',
      tabletId: json['tabletId'] as String?,
      operatorId: json['operatorId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'documentNumber': documentNumber,
      'documentType': documentType,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'nationality': nationality,
      'photoBase64': photoBase64,
      'faceEmbedding': faceEmbedding,
      'matchScore': matchScore,
      'status': status,
      'tabletId': tabletId,
      'operatorId': operatorId,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get fullName => '$firstName $lastName';

  @override
  String toString() {
    return 'BiometricRecordModel(id: $id, name: $fullName, document: $documentNumber)';
  }
}

/// Modelo de solicitud de registro biométrico
class BiometricRegistrationRequest {
  final String documentNumber;
  final String documentType;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String? gender;
  final String? nationality;
  final String photoBase64;
  final String? faceEmbedding;
  final String? tabletId;
  final String? operatorId;
  final Map<String, dynamic>? metadata;

  BiometricRegistrationRequest({
    required this.documentNumber,
    required this.documentType,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.gender,
    this.nationality,
    required this.photoBase64,
    this.faceEmbedding,
    this.tabletId,
    this.operatorId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'documentNumber': documentNumber,
      'documentType': documentType,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'nationality': nationality,
      'photoBase64': photoBase64,
      'faceEmbedding': faceEmbedding,
      'tabletId': tabletId,
      'operatorId': operatorId,
      'metadata': metadata,
    };
  }
}

/// Modelo de solicitud de validación biométrica
class BiometricValidationRequest {
  final String photoBase64;
  final String? faceEmbedding;
  final String? documentNumber;
  final String? tabletId;

  BiometricValidationRequest({
    required this.photoBase64,
    this.faceEmbedding,
    this.documentNumber,
    this.tabletId,
  });

  Map<String, dynamic> toJson() {
    return {
      'photoBase64': photoBase64,
      'faceEmbedding': faceEmbedding,
      'documentNumber': documentNumber,
      'tabletId': tabletId,
    };
  }
}

/// Modelo de respuesta de validación biométrica
class BiometricValidationResponse {
  final bool success;
  final bool isMatch;
  final double? matchScore;
  final BiometricRecordModel? matchedRecord;
  final String? message;

  BiometricValidationResponse({
    required this.success,
    required this.isMatch,
    this.matchScore,
    this.matchedRecord,
    this.message,
  });

  factory BiometricValidationResponse.fromJson(Map<String, dynamic> json) {
    return BiometricValidationResponse(
      success: json['success'] ?? false,
      isMatch: json['isMatch'] ?? false,
      matchScore: json['matchScore'] != null
          ? (json['matchScore'] as num).toDouble()
          : null,
      matchedRecord: json['matchedRecord'] != null
          ? BiometricRecordModel.fromJson(
              json['matchedRecord'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}
