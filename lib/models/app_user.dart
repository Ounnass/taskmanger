class AppUser {
  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
  });

  final String? id;
  final String name;
  final String email;
  final String password;
  final String role;

  bool get isAdmin => role == 'admin';

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };
}
