class Publikasi {
  const Publikasi({
    required this.id,
    required this.judul,
    required this.dibuatPada,
    this.thumbnail,
    this.tautan,
  });

  final String id;
  final String judul;
  final String dibuatPada;
  final String? thumbnail;
  final String? tautan;

  factory Publikasi.fromJson(Map<String, dynamic> j) {
    return Publikasi(
      id: (j['id'] as String?)?.trim() ?? '',
      judul: (j['title'] as String?)?.trim() ?? '',
      dibuatPada: (j['created_at'] as String?)?.trim() ?? '',
      thumbnail: (j['thumbnail'] as String?)?.trim(),
      tautan: (j['link'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': judul,
        'created_at': dibuatPada,
        'thumbnail': thumbnail,
        'link': tautan,
      };
}

