/// [bytes] as a short size for people: three significant figures in the
/// biggest unit that keeps it under about 900 (`950 B` is shown as
/// `0.93 KB`), whole numbers for plain bytes.
String readableBytes(num bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  final last = units.length - 1;

  var size = bytes.toDouble();
  var unit = 0;
  while (unit < last && size >= 1024) {
    size /= 1024;
    unit++;
  }
  if (unit < last && size > 900) {
    size /= 1024;
    unit++;
  }

  final decimals = unit == 0
      ? 0
      : size < 10
      ? 2
      : size < 100
      ? 1
      : 0;
  return '${size.toStringAsFixed(decimals)} ${units[unit]}';
}
