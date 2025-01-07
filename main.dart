import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CategoryDropdown(),
    );
  }
}

class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({super.key});

  @override
  _CategoryDropdownState createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  List<Map<String, dynamic>> _categories = [];
  List<String> _subCategories = [];
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedCategoryId; // Stores selected category ID
  bool _isLoadingCategories = true;
  bool _isLoadingSubCategories = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Fetch categories from the API
  Future<void> _fetchCategories() async {
    const apiUrl = 'https://devtechtop.com/management/public/api/categories';

    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final response = await http.post(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        setState(() {
          _categories = jsonResponse
              .map((item) => {
                    'id': item['id'], // category_id
                    'category_name': item['category_name'], // category name
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to fetch categories');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  // Fetch subcategories based on selected category
  Future<void> _fetchSubCategories(String categoryId) async {
  const apiUrl =
      'https://devtechtop.com/management/public/api/select_subcategories';

  setState(() {
    _isLoadingSubCategories = true;
    _subCategories.clear();
  });

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'}, // Ensure JSON format
      body: jsonEncode({'category_id': categoryId}),
    );

    print('Response Status Code: ${response.statusCode}'); // Debug log
    print('Response Body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true) {
        final data = jsonResponse['data'] as List<dynamic>;
        setState(() {
          _subCategories = data
              .map<String>((item) => item['subcategory'].toString())
              .toList();
        });
      } else {
        throw Exception('API returned success: false');
      }
    } else {
      throw Exception('Failed to fetch subcategories: ${response.body}');
    }
  } catch (e) {
    print('Error fetching subcategories: $e'); // Log error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() {
      _isLoadingSubCategories = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & Subcategories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Dropdown
            _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : DropdownButton<String>(
                    hint: const Text('Select a category'),
                    value: _selectedCategory,
                    onChanged: (String? newValue) {
                      final selectedCategory = _categories.firstWhere(
                          (category) =>
                              category['category_name'] == newValue,
                          orElse: () => {});
                      setState(() {
                        _selectedCategory = newValue;
                        _selectedCategoryId =
                            selectedCategory['id']?.toString(); // Null-safe
                        _selectedSubCategory = null;
                      });

                      if (_selectedCategoryId != null) {
                        _fetchSubCategories(_selectedCategoryId!);
                      }
                    },
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['category_name'],
                        child: Text(category['category_name']),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 20),

            // Subcategory Dropdown
            _isLoadingSubCategories
                ? const Center(child: CircularProgressIndicator())
                : DropdownButton<String>(
                    hint: const Text('Select a subcategory'),
                    value: _selectedSubCategory,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubCategory = newValue;
                      });
                    },
                    items: _subCategories.map((subCategory) {
                      return DropdownMenuItem<String>(
                        value: subCategory,
                        child: Text(subCategory),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
