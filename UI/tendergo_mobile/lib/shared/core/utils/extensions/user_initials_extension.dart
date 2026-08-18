import 'package:tendergo/shared/models/has_initials.dart';

extension UserInitialsExtension on HasInitials {
String get initials {
    String res = "";
    
    if (firstName.trim().isNotEmpty) res += firstName.trim()[0];
    if (lastName.trim().isNotEmpty) res += lastName.trim()[0];
    if (res.isNotEmpty) return res.toUpperCase();
    
    if (userName.trim().isNotEmpty) return userName.trim()[0].toUpperCase();
    
    return '?';
  }
      String get fullName => "$firstName $lastName";

}