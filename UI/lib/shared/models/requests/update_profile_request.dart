import 'dart:convert';
import 'dart:typed_data';

import 'package:tendergo/shared/models/requests/update_address_request.dart';


class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final UpdateAddressDto? address;
   final List<Uint8List>? imageBytes;


  UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.address,
    this.imageBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address!.toJson(),
        'imageBytes': imageBytes?.map((bytes) => base64Encode(bytes)).toList(),
    };
  }
}