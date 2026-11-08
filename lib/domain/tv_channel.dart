class TvChannel {
  const TvChannel({
    required this.name,
    required this.url,
    this.logo = '',
    this.group = 'General',
    this.tvgId = '',
    this.country = '',
    this.language = '',
  });

  final String name;
  final String url;
  final String logo;
  final String group;
  final String tvgId;
  final String country;
  final String language;
}
