import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';

class ErrorHandler {
  static String? extractErrorMessage(dynamic data) {
    if (data == null) return null;

    try {
  
      if (data is Map<String, dynamic>) {
        final msg = data['message'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }

        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        }

        if (data.containsKey('errors') && data['errors'] is Map<String, dynamic>) {
          final mapErrors = data['errors'] as Map<String, dynamic>;
          if (mapErrors.isNotEmpty) {
            final firstKey = mapErrors.keys.first;
            final errorList = mapErrors[firstKey];
            if (errorList is List && errorList.isNotEmpty) {
              return errorList.first.toString();
            }
            if (errorList is String && errorList.trim().isNotEmpty) {
              return errorList;
            }
          }
        }

        if (data['errors'] == "OWNER_CANNOT_BID") {
        return 'You cannot place an offer on your own tender.';
      }
      }

      if (data is String && data.trim().isNotEmpty) return data;
    } catch (_) {
    }

    return null;
  }

  static bool isAccountBanned(dynamic data) {
    final code = extractErrorMessage(data);
    if (code == 'ACCOUNT_BANNED') return true;
    if (data is Map && data['errors'] is List) {
      return (data['errors'] as List)
          .any((e) => e.toString() == 'ACCOUNT_BANNED');
    }
    return false;
  }

  static String accountBannedMessage() =>
      'Your account has been banned.';

  static void showApiError(BuildContext context, ApiResponse api) {
    final msg = switch (api.statusCode) {
      400 => api.message.isNotEmpty ? api.message : 'Request is not valid.',
      401 => 'Please sign in again.',
      403 => 'You don’t have permission to do that.',
      404 => 'Not found.',
      409 => api.message.isNotEmpty ? api.message : 'Conflict. Please retry.',
      500 => 'Server error. Please try again later.',
      _ => api.message.isNotEmpty ? api.message : 'Something went wrong.',
    };

    final details = (api.errors != null && api.errors!.isNotEmpty)
        ? '\n${api.errors!.take(3).join('\n')}'
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$msg$details')),
    );
  }
}