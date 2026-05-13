import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/models/listing.dart';
import 'package:mobile_app/features/search/data/search_repository.dart';

final searchControllerProvider = StateNotifierProvider<SearchController, AsyncValue<List<Listing>>>((ref) {
  return SearchController(ref.watch(searchRepositoryProvider));
});

class SearchController extends StateNotifier<AsyncValue<List<Listing>>> {
  final SearchRepository _repository;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  SearchController(this._repository) : super(const AsyncValue.data([])) {
    // Load initial listings
    search();
  }

  Future<void> search({String? query}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.searchListings(
      query: query,
      category: _selectedCategory,
    ));
  }
  
  void selectCategory(String category) {
    if (_selectedCategory == category) {
      _selectedCategory = null; // Deselect if already selected
    } else {
      _selectedCategory = category;
    }
    search(); // Trigger search with new category
  }
}
