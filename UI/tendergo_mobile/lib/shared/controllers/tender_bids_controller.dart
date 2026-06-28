import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class TenderBidsController with ChangeNotifier {
  TenderBidsController({
    required int tenderId,
    required TenderDto tender,
    required TenderService tenderService,
    required BidService bidService,
  })  : _tenderId = tenderId,
        tender = tender,
        _tenderService = tenderService,
        _bidService = bidService;

  final int _tenderId;
  final TenderService _tenderService;
  final BidService _bidService;
  TenderDto tender;

  List<BidDto> bids = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';

  Future<void> load() => _fetch();

  Future<void> refresh() => _fetch();

  Future<void> award(BidDto bid) async {
    tender = await _tenderService.award(tender, bid.id);
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
