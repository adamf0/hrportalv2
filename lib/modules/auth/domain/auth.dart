class AuthSession {
  final String name;
  final String nip;
  final String email;
  final String role;
  final List<String> groups;
  final String token;

  AuthSession({
    required this.name,
    required this.nip,
    required this.email,
    required this.role,
    required this.groups,
    required this.token,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json, String token) {
    final groupsRaw = json['group'] ?? json['groups'] ?? [];
    final List<String> groupList =
        groupsRaw is List ? groupsRaw.map((e) => e.toString()).toList() : [];

    final String resolvedRole =
        groupList.contains('Tendik') ? 'Tendik' : 'Dosen';

    return AuthSession(
      name: json['name'] ?? 'User',
      nip: json['employeeid'] ?? '',
      email: json['email'] ?? '',
      role: resolvedRole,
      groups: groupList,
      token: token,
    );
  }

  bool get isSdm {
    if (role.toLowerCase() == 'sdm') return true;
    const sdmGroups = [
      'sdm',
    ];
    for (var g in groups) {
      final gLower = g.toLowerCase();
      if (gLower.contains('sdm') || sdmGroups.contains(gLower)) {
        return true;
      }
    }
    return false;
  }
}
