class Ngo {
  final String id;
  final String name;
  final String? logoUrl;
  final bool verified;

  const Ngo({
    required this.id,
    required this.name,
    this.logoUrl,
    this.verified = false,
  });
}
