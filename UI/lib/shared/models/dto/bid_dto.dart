class BidDto {
	final int id;
	final int tenderId;
	final String tenderTitle;
	final String tenderCreatedByUserId;
	final String? tenderCreatedByUserName;
	final String submittedByUserId;
	final String submittedByUserName;
	final double offeredPrice;
	final DateTime submittedAt;
	final ApplicationStatus status;
	final String? proposal;
	final int? deliveryDays;

	const BidDto({
		required this.id,
		required this.tenderId,
		required this.tenderTitle,
		required this.tenderCreatedByUserId,
		this.tenderCreatedByUserName,
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

	static String _readFirstNonEmptyString(List<dynamic> values, {String fallback = ''}) {
		for (final value in values) {
			final parsed = _readString(value).trim();
			if (parsed.isNotEmpty) {
				return parsed;
			}
		}
		return fallback;
	}

	static String? _readNullableString(dynamic value) {
		if (value == null) return null;
		final parsed = _readString(value).trim();
		return parsed.isEmpty ? null : parsed;
	}

	static ApplicationStatus _readStatus(dynamic value) {
		if (value is int) {
			return ApplicationStatus.values.firstWhere(
				(e) => e.value == value,
				orElse: () => ApplicationStatus.pending,
			);
		}
		final str = _readString(value).toLowerCase();
		return ApplicationStatus.values.firstWhere(
			(e) => e.name.toLowerCase() == str,
			orElse: () => ApplicationStatus.pending,
		);
	}

	static DateTime _readDateTime(dynamic value) {
		if (value is DateTime) return value;
		if (value is String) {
			return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
		}
		return DateTime.fromMillisecondsSinceEpoch(0);
	}

	String get tenderDisplayTitle {
		final parsed = tenderTitle.trim();
		return parsed.isNotEmpty ? parsed : 'Untitled tender';
	}

	factory BidDto.fromJson(Map<String, dynamic> json) {
		final tender = json['tender'];
		final tenderMap = tender is Map<String, dynamic> ? tender : null;

		return BidDto(
			id: _readInt(json['id']),
			tenderId: _readInt(json['tenderId']),
			tenderTitle: _readFirstNonEmptyString([
				json['tenderTitle'],
				json['tender_name'],
				json['tenderName'],
				json['title'],
				tenderMap?['tenderTitle'],
				tenderMap?['name'],
				tenderMap?['title'],
			]),
			tenderCreatedByUserId: _readFirstNonEmptyString([
				json['tenderCreatedByUserId'],
				json['createdByUserId'],
				tenderMap?['createdByUserId'],
				tenderMap?['userId'],
			]),
			tenderCreatedByUserName: _readNullableString(
				_readFirstNonEmptyString([
					json['tenderCreatedByUserName'],
					json['createdByUserName'],
					json['createdByFullname'],
					tenderMap?['createdByUserName'],
					tenderMap?['createdByFullname'],
					tenderMap?['userName'],
				]),
			),
			submittedByUserId: _readString(json['submittedByUserId']),
			submittedByUserName: _readString(json['submittedByUserName']),
			offeredPrice: _readDouble(json['offeredPrice']),
			submittedAt: _readDateTime(json['submittedAt']),
			status: _readStatus(json['status']),
			proposal: _readNullableString(json['proposal']),
			deliveryDays: json['deliveryDays'] == null
					? null
					: _readInt(json['deliveryDays']),
		);
	}

   	static BidDto parseBid(dynamic data) {
		if (data is Map<String, dynamic>) {
			return BidDto.fromJson(data);
		}

		throw const FormatException('Invalid bid payload format.');
	}

	static List<BidDto> parseBidList(dynamic data) {

    if(data == null) {
      return [];
    }

		if (data is List) {
       if (data.isEmpty) return [];
			return data
				.whereType<Map<String, dynamic>>()
				.map(BidDto.fromJson)
				.toList();
		}

		if (data is Map<String, dynamic>) {
			final dynamic listLike =
        data['result'] ??   
        data['items'] ??
        data['data'] ??
        data['results'];
        if (listLike == null) return [];
        
			if (listLike is List) {
				return listLike
					.whereType<Map<String, dynamic>>()
					.map(BidDto.fromJson)
					.toList();
			}
		}

		throw const FormatException('Invalid bids payload format.');
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'tenderId': tenderId,
			'tenderTitle': tenderTitle,
			'tenderCreatedByUserId': tenderCreatedByUserId,
			'tenderCreatedByUserName': tenderCreatedByUserName,
			'submittedByUserId': submittedByUserId,
			'submittedByUserName': submittedByUserName,
			'offeredPrice': offeredPrice,
			'submittedAt': submittedAt.toIso8601String(),
			'status': status.name,
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
enum ApplicationStatus {
  pending(1),
  accepted(2),
  rejected(3),
  withdrawn(4);

  final int value;
  const ApplicationStatus(this.value);
}