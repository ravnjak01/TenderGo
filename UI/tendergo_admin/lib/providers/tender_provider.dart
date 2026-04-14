// lib/providers/tender_provider.dart

import 'package:file_picker/file_picker.dart';
import 'package:tendergo_admin/services/category_service.dart';

import '../models/dto/tender_dto.dart';
import '../models/dto/tender_post_dto.dart';
import '../models/enums/tenderstatus.dart';
import '../services/tender_service.dart';
import 'package:flutter/material.dart';

class TenderProvider extends ChangeNotifier {
  final TenderService _service;
  final CategoryService _categoryService;

  TenderProvider(this._service, this._categoryService);

  // --- State ---
  List<TenderDto> _tenders = [];
  List<String> _categories = ['All'];
  final Set<String> _selectedCategories = {'All'}; // Set za lakše filtriranje

  bool _isLoading = false;
  String? _error;

  // --- Getters ---
  List<TenderDto> get tenders => _tenders;
  List<String> get categories => _categories;
  Set<String> get selectedCategories => _selectedCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // LOGIKA FILTRIRANJA: Ovo je ključni dio koji "stanjuje" UI
  List<TenderDto> get filteredTenders {
    if (_selectedCategories.contains('All') || _selectedCategories.isEmpty) {
      return _tenders;
    }
    return _tenders
        .where((t) => _selectedCategories.contains(t.categoryName))
        .toList();
  }

  // --- Actions ---

  // Učitavanje kategorija
  Future<void> fetchCategories() async {
    try {
      final apiCategories = await _categoryService.getAll();
      _categories = ['All', ...apiCategories.map((c) => c.name)];
      notifyListeners();
    } catch (e) {
      debugPrint('Greška pri učitavanju kategorija: $e');
    }
  }

  // Promjena kategorije (logika koju si imao u setState)
  void toggleCategory(String category) {
    if (category == 'All') {
      _selectedCategories.clear();
      _selectedCategories.add('All');
    } else {
      _selectedCategories.remove('All');

      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }

      // Ako je sve odznačeno, vrati na 'All'
      if (_selectedCategories.isEmpty) {
        _selectedCategories.add('All');
      }
    }
    notifyListeners();
  }

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

  Future<TenderDto> createTender(
    TenderInsertRequest request, {
    List<PlatformFile>? imageFiles,
  }) async {
    final createdTender = await _service.create(
      request,
      imageFiles: imageFiles,
    );
    _error = null;

    if (createdTender.status == TenderStatus.open) {
      final existingIndex = _tenders.indexWhere(
        (t) => t.id == createdTender.id,
      );
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
