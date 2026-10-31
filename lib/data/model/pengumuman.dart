class Pengumuman {
  const Pengumuman({
    required this.id,
    required this.judul,
    required this.slug,
    required this.deskripsi,
    required this.dibuatPada,
    this.tautan,
  });

  final String id;
  final String judul;
  final String slug;
  final String deskripsi;
  final String dibuatPada;
  final String? tautan;

  factory Pengumuman.fromJson(Map<String, dynamic> j) {
    return Pengumuman(
      id: (j['id'] as String?)?.trim() ?? '',
      judul: (j['title'] as String?)?.trim() ?? '',
      slug: (j['slug'] as String?)?.trim() ?? '',
      deskripsi: (j['description'] as String?)?.trim() ?? '',
      dibuatPada: (j['created_at'] as String?)?.trim() ?? '',
      tautan: (j['link'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': judul,
        'slug': slug,
        'description': deskripsi,
        'created_at': dibuatPada,
        'link': tautan,
      };
}

