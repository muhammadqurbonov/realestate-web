/// Cloudinary метавонад бо иловаи "fl_attachment" ба URL, боркуниро
/// маҷбурӣ кунад (на кушодан дар браузер, балки боргирӣ). Мисол:
/// https://res.cloudinary.com/x/image/upload/v123/a.jpg
/// -> https://res.cloudinary.com/x/image/upload/fl_attachment/v123/a.jpg
String cloudinaryDownloadUrl(String url) {
  const marker = '/upload/';
  final index = url.indexOf(marker);
  if (index == -1) return url;
  final insertAt = index + marker.length;
  return '${url.substring(0, insertAt)}fl_attachment/${url.substring(insertAt)}';
}
