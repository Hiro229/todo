class User {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    required this.isVerified,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? username,
    String? fullName,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

class UserRegistration {
  final String email;
  final String username;
  final String password;
  final String? fullName;

  UserRegistration({
    required this.email,
    required this.username,
    required this.password,
    this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'full_name': fullName,
    };
  }
}

class UserLogin {
  final String email;
  final String password;

  UserLogin({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class UserUpdate {
  final String? email;
  final String? username;
  final String? fullName;
  final String? password;

  UserUpdate({
    this.email,
    this.username,
    this.fullName,
    this.password,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (email != null) data['email'] = email;
    if (username != null) data['username'] = username;
    if (fullName != null) data['full_name'] = fullName;
    if (password != null) data['password'] = password;
    return data;
  }
}

class AuthResponse {
  final String message;
  final User user;
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  AuthResponse({
    required this.message,
    required this.user,
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'],
      user: User.fromJson(json['user']),
      accessToken: json['access_token'],
      tokenType: json['token_type'] ?? 'bearer',
      expiresIn: json['expires_in'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': user.toJson(),
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
    };
  }
}