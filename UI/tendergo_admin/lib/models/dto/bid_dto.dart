class BidDto {
	final int id;
	final int tenderId;
	final String tenderTitle;
	final String submittedByUserId;
	final String submittedByUserName;
	final double offeredPrice;
	final DateTime submittedAt;
	final String status;
	final String? proposal;
	final int? deliveryDays;

	const BidDto({
		required this.id,
		required this.tenderId,
		required this.tenderTitle,
		required this.submittedByUserId,
		required this.submittedByUserName,
		required this.offeredPrice,
		required this.submittedAt,
		required this.status,
		this.proposal,
		this.deliveryDays,
	});

	static int _readInt(dynamic value, {int fallback = 0}) {
		if (value is int) return value;
		if (value is num) return value.toInt();
		if (value is String) return int.tryParse(value) ?? fallback;
		return fallback;
	}

	static double _readDouble(dynamic value, {double fallback = 0}) {
		if (value is double) return value;
		if (value is num) return value.toDouble();
		if (value is String) return double.tryParse(value) ?? fallback;
		return fallback;
	}

	static String _readString(dynamic value, {String fallback = ''}) {
		if (value is String) return value;
		if (value == null) return fallback;
		return value.toString();
	}

	static String? _readNullableString(dynamic value) {
		if (value == null) return null;
		final parsed = _readString(value).trim();
		return parsed.isEmpty ? null : parsed;
	}

	static DateTime _readDateTime(dynamic value) {
		if (value is DateTime) return value;
		if (value is String) {
			return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
		}
		return DateTime.fromMillisecondsSinceEpoch(0);
	}

	factory BidDto.fromJson(Map<String, dynamic> json) {
		return BidDto(
			id: _readInt(json['id']),
			tenderId: _readInt(json['tenderId']),
			tenderTitle: _readString(json['tenderTitle']),
			submittedByUserId: _readString(json['submittedByUserId']),
			submittedByUserName: _readString(json['submittedByUserName']),
			offeredPrice: _readDouble(json['offeredPrice']),
			submittedAt: _readDateTime(json['submittedAt']),
			status: _readString(json['status']),
			proposal: _readNullableString(json['proposal']),
			deliveryDays: json['deliveryDays'] == null
					? null
					: _readInt(json['deliveryDays']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'tenderId': tenderId,
			'tenderTitle': tenderTitle,
			'submittedByUserId': submittedByUserId,
			'submittedByUserName': submittedByUserName,
			'offeredPrice': offeredPrice,
			'submittedAt': submittedAt.toIso8601String(),
			'status': status,
			'proposal': proposal,
			'deliveryDays': deliveryDays,
		};
	}
}

class BidInsertRequest {
  final double price;
  final int tenderId;
  final String? note;
	final int? userId;

  BidInsertRequest({
    required this.price,
    required this.tenderId,
		this.userId,
    this.note,
  });

  Map<String, dynamic> toJson() {
		final payload = <String, dynamic>{
      'price': price,
      'tenderId': tenderId,
      'note': note,
    };

		if (userId != null) {
			payload['userId'] = userId;
		}

		return payload;
  }
}