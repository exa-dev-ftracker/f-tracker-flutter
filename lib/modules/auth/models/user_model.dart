class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final bool chatbotEnabled;
  final String timezone;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.chatbotEnabled = false,
    this.timezone = 'UTC',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      chatbotEnabled: json['chatbot_enabled'] == true,
      timezone: json['timezone']?.toString() ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'chatbot_enabled': chatbotEnabled,
    'timezone': timezone,
  };
}
