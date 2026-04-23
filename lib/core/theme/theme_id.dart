enum ThemeId {
  pureCinematic(
    key: 'pure_cinematic',
    displayName: 'Pure Cinematic',
    displayNameKo: '순정 시네마',
    description: '순검정 + 영화 자막체. 여백과 정적의 미니멀 영화.',
    priceKrw: 0,
    productId: null,
    comingSoon: false,
  ),
  filmNoir(
    key: 'film_noir',
    displayName: 'Film Noir',
    displayNameKo: '필름 느와르',
    description: '1940년대 탐정 영화. 크림 + 골드 + 와인 레드.',
    priceKrw: 5500,
    productId: 'shadowrun_theme_noir',
    comingSoon: false,
  ),
  koreanMystic(
    key: 'korean_mystic',
    displayName: 'Korean Mystic',
    displayNameKo: '한국 민속 호러',
    description: '나눔명조 + 한자 워터마크. 곡성·파묘 감성.',
    priceKrw: 5500,
    productId: 'shadowrun_theme_mystic',
    comingSoon: false,
  ),
  editorial(
    key: 'editorial',
    displayName: 'Editorial Thriller',
    displayNameKo: '에디토리얼 스릴러',
    description: 'GQ 매거진 스타일. 거대 세리프 로고 + 이슈 번호.',
    priceKrw: 5500,
    productId: 'shadowrun_theme_editorial',
    comingSoon: false,
  ),
  neoNoirCyber(
    key: 'neo_noir_cyber',
    displayName: 'Neo-Noir Cyber',
    displayNameKo: '네오 느와르 사이버',
    description: '블레이드러너. 붉은 네온 + 차가운 시안.',
    priceKrw: 5500,
    productId: 'shadowrun_theme_cyber',
    comingSoon: false,
  );

  final String key;
  final String displayName;
  final String displayNameKo;
  final String description;
  final int priceKrw;
  final String? productId;
  final bool comingSoon;

  const ThemeId({
    required this.key,
    required this.displayName,
    required this.displayNameKo,
    required this.description,
    required this.priceKrw,
    required this.productId,
    required this.comingSoon,
  });

  bool get isFree => productId == null;

  static ThemeId fromKey(String? k) {
    if (k == null) return ThemeId.pureCinematic;
    for (final v in ThemeId.values) {
      if (v.key == k) return v;
    }
    return ThemeId.pureCinematic;
  }
}
