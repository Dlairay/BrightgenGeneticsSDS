class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  
  AuthResponse({
    required this.accessToken,
    this.refreshToken,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final List<Child> children;
  final DateTime? createdAt;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.children,
    this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      children: (json['children'] as List<dynamic>? ?? [])
          .map((child) => Child.fromJson(child))
          .toList(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'children': children.map((child) => child.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class Child {
  final String id;
  final String name;
  final String? gender;
  final String? birthday;
  final DateTime? createdAt;
  
  Child({
    required this.id,
    required this.name,
    this.gender,
    this.birthday,
    this.createdAt,
  });
  
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'],
      birthday: json['birthday'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'birthday': birthday,
      'created_at': createdAt?.toIso8601String(),
    };
  }
  
  // Helper getter for age calculation
  int? get ageInMonths {
    if (birthday == null) return null;
    final birthDate = DateTime.tryParse(birthday!);
    if (birthDate == null) return null;
    
    final now = DateTime.now();
    
    // Calculate proper months difference
    int months = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    
    // Adjust if we haven't reached the birth day in the current month
    if (now.day < birthDate.day) {
      months--;
    }
    
    return months;
  }
}

class LoginRequest {
  final String email;
  final String password;
  
  LoginRequest({
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

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  
  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
    };
  }
}