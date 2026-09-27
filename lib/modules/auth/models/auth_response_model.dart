class AuthResponseModel {
  final String accessToken;
  final String refreshToken;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken']?.toString() ?? json['access_token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? json['refresh_token']?.toString() ?? '',
    );
  }
}
