class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final bool chatbotEnabled;
  final String timezone;
  final String? googleId;
  final String? googleEmail;
  final bool isGoogleLinked;
  final String? appleId;
  final String? appleEmail;
  final bool isAppleLinked;
  final bool isAppleRegistered;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.chatbotEnabled = false,
    this.timezone = 'UTC',
    this.googleId,
    this.googleEmail,
    this.isGoogleLinked = false,
    this.appleId,
    this.appleEmail,
    this.isAppleLinked = false,
    this.isAppleRegistered = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final appleId = json['apple_id']?.toString();
    final googleId = json['google_id']?.toString();
    final isAppleReg = json['is_apple_registered'] == true ||
        (appleId != null &&
            appleId.isNotEmpty &&
            (json['password'] == null ||
                (json['email']?.toString().contains('privaterelay.appleid.com') ?? false)));

    final isGoogleLinked = json['is_google_linked'] == true ||
        (googleId != null && googleId.isNotEmpty) ||
        (!isAppleReg && json['email'] != null);

    final isAppleLinked = json['is_apple_linked'] == true ||
        (appleId != null && appleId.isNotEmpty);

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      chatbotEnabled: json['chatbot_enabled'] == true,
      timezone: json['timezone']?.toString() ?? 'UTC',
      googleId: googleId,
      googleEmail: json['google_email']?.toString() ?? (isGoogleLinked ? json['email']?.toString() : null),
      isGoogleLinked: isGoogleLinked,
      appleId: appleId,
      appleEmail: json['apple_email']?.toString(),
      isAppleLinked: isAppleLinked,
      isAppleRegistered: isAppleReg,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'chatbot_enabled': chatbotEnabled,
    'timezone': timezone,
    'google_id': googleId,
    'google_email': googleEmail,
    'is_google_linked': isGoogleLinked,
    'apple_id': appleId,
    'apple_email': appleEmail,
    'is_apple_linked': isAppleLinked,
    'is_apple_registered': isAppleRegistered,
  };
}
