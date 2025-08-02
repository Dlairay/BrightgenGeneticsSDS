class UserModel {
  final String id;
  final String email;
  final String phone;
  final String babyName;
  final String? profileImageUrl;
  
  UserModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.babyName,
    this.profileImageUrl,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      babyName: json['babyName'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'babyName': babyName,
      'profileImageUrl': profileImageUrl,
    };
  }
}