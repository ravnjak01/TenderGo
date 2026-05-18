import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/application_status.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class TenderBidsController with ChangeNotifier {
  TenderBidsController({
    required int tenderId,
    required TenderDto tender,
    required TenderService tenderService,
    required BidService bidService,
  })  : _tenderId = tenderId,
        _tender = tender,
        _tenderService = tenderService,
        _bidService = bidService;

  final int _tenderId;
  final TenderDto _tender;
  final TenderService _tenderService;
  final BidService _bidService;

  List<BidDto> bids = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';

  Future<void> load() => _fetch();

  Future<void> refresh() => _fetch();

  Future<void> award(BidDto bid) async {
    await _tenderService.award(_tender, bid.id);

    final rejectFutures = bids
        .where((item) => item.id != bid.id && item.status == ApplicationStatus.pending)
        .map((item) => _bidService.update(item.id, {'status': 'rejected'}));
    await Future.wait(rejectFutures);
    await refresh();
  }

  Future<void> _fetch() async {
    isLoading = true;
    hasError = false;
    errorMessage = '';
    notifyListeners();

    try {
      bids = await _bidService.getByTender(_tenderId);
    } catch (e) {
      hasError = true;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
