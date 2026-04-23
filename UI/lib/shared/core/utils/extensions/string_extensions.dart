
  extension StringExtensions on String {
  String toRoleLabel() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

//metoda za prikazivanje vremena proteklog od objave tendera
  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)   return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

//metoda za prikazivanje fiksnog datuma isteka tendera
  String formatDeadline(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

//metoda za formatiranje novcanih vrijednosti
  String formatValue(double v) {
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      // insert dot every 3 digits from right
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return '${buf.toString()} KM';
    }
    return '${v.toStringAsFixed(0)} KM';
  }


 