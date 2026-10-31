class Pagination {
  const Pagination({
    required this.page,
    required this.pageSize,
    required this.totalPage,
    required this.totalItems,
  });

  final int page;
  final int pageSize;
  final int totalPage;
  final int totalItems;

  bool get adaLanjutan => page < totalPage;

  factory Pagination.fromJson(Map<String, dynamic> j) {
    int ambilInt(dynamic v, int bawaan) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? bawaan;
      return bawaan;
    }

    return Pagination(
      page: ambilInt(j['page'], 1),
      pageSize: ambilInt(j['page_size'], 10),
      totalPage: ambilInt(j['total_page'], 1),
      totalItems: ambilInt(j['total_items'], 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'page_size': pageSize,
        'total_page': totalPage,
        'total_items': totalItems,
      };
}

class Halaman<T> {
  const Halaman({
    required this.items,
    required this.pagination,
  });

  final List<T> items;
  final Pagination pagination;
}

