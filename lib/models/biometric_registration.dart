class BiometricRegistration {
  final String documentNumber;
  final String documentType;
  final DateTime expeditionDate;
  final String selfieBase64;
  final String frontDocumentBase64;
  final String backDocumentBase64;
  final bool termsAccepted;
  final String emotion;
  final DeviceInfoModel? deviceInfo;
  final TabletInfoModel? tabletInfo;

  BiometricRegistration({
    required this.documentNumber,
    required this.documentType,
    required this.expeditionDate,
    required this.selfieBase64,
    required this.frontDocumentBase64,
    required this.backDocumentBase64,
    required this.termsAccepted,
    this.emotion = 'neutral',
    this.deviceInfo,
    this.tabletInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'documentNumber': documentNumber,
      'documentType': documentType,
      'expeditionDate': expeditionDate.toIso8601String().split('T')[0],
      'selfieBase64': selfieBase64,
      'frontDocumentBase64': frontDocumentBase64,
      'backDocumentBase64': backDocumentBase64,
      'termsAccepted': termsAccepted,
      'emotion': emotion,
      'deviceInfo': deviceInfo?.toJson(),
      'tabletInfo': tabletInfo?.toJson(),
    };
  }
}

class DeviceInfoModel {
  final String deviceId;
  final String deviceModel;
  final String osVersion;
  final String appVersion;

  DeviceInfoModel({
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'appVersion': appVersion,
    };
  }
}

class TabletInfoModel {
  final String tabletId;
  final LocationModel? location;
  final String? registeredBy;

  TabletInfoModel({
    required this.tabletId,
    this.location,
    this.registeredBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'tabletId': tabletId,
      'location': location?.toJson(),
      'registeredBy': registeredBy,
    };
  }
}

class LocationModel {
  final double latitude;
  final double longitude;

  LocationModel({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}