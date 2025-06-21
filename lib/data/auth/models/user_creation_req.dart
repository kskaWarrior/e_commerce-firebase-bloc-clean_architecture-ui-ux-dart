class UserCreationReq {
  final String email;
  final String password;
  final String? name;
  final String? phone;

  UserCreationReq({
    required this.email,
    required this.password,
    this.name,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
    };
  }
  factory UserCreationReq.fromJson(Map<String, dynamic> json) {
    return UserCreationReq(
      email: json['email'],
      password: json['password'],
      name: json['name'],
      phone: json['phone'],
    );
  }
}