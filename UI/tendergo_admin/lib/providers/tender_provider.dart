// lib/providers/tender_provider.dart

import '../models/dto/tender_dto.dart';
import '../models/dto/tender_post_dto.dart';
import '../models/enums/tenderstatus.dart';
import '../services/tender_service.dart';
import 'package:flutter/material.dart';

class TenderProvider extends ChangeNotifier {
  final TenderService _service;

  TenderProvider(this._service);

  TenderService get service => _service;

  List<TenderDto > _tenders = [];
  bool _isLoading = false;
  String? _error;

  List<TenderDto > get tenders => _tenders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Metoda koja setuje loading i obavještava UI
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch aktivne tendere
  Future<void> fetchActiveTenders() async {
    _setLoading(true);
    try {
      _tenders = await _service.getActive(); 
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _tenders = []; // po grešci prazna lista
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllTenders() async {
    _setLoading(true);
    try {
      _tenders = await _service.getAll(); // add getAll() to service
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<TenderDto> createTender(TenderInsertRequest request) async {
    final createdTender = await _service.create(request);
    _error = null;

    if (createdTender.status == TenderStatus.open) {
      final existingIndex = _tenders.indexWhere((t) => t.id == createdTender.id);
      if (existingIndex >= 0) {
        _tenders[existingIndex] = createdTender;
      } else {
        _tenders = [createdTender, ..._tenders];
      }
      notifyListeners();
    }

    return createdTender;
  }

  Future<bool> deleteTender(int id) async {
    try {
      await _service.delete(id);
      _tenders.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }


}