class UserModel {
  final int id;
  final String email;
  final String username;
  final String password;
  final String accountType;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.accountType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      accountType: json['account_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'account_type': accountType,
    };
  }
}