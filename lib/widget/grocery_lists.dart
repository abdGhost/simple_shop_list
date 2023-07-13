import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shop_test_app/data/categories.dart';
import 'package:shop_test_app/model/grocery_item.dart';
import 'package:shop_test_app/widget/new_item.dart';

import 'package:http/http.dart' as http;

class GroceryLists extends StatefulWidget {
  const GroceryLists({super.key});

  @override
  State<GroceryLists> createState() => _GroceryListsState();
}

class _GroceryListsState extends State<GroceryLists> {
  List<GroceryItem> _goceryItems = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }

    setState(() {
      _goceryItems.add(newItem);
      _isLoading = false;
    });
  }

  void _loadItems() async {
    final url = Uri.https(
        'testshop-607d9-default-rtdb.firebaseio.com', 'shoping-list.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch the data. Please try again later.';
      });
    }

    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value['category'],
          )
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _goceryItems = loadedItems;
    });
  }

  void _removeItem(GroceryItem groceryItem) async {
    var index = _goceryItems.indexOf(groceryItem);
    setState(() {
      _goceryItems.remove(groceryItem);
    });

    final url = Uri.https('testshop-607d9-default-rtdb.firebaseio.com',
        'shoping-list/${groceryItem.id}.json');
    var response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _goceryItems.insert(index, groceryItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No item added yet'));

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_goceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _goceryItems.length,
        itemBuilder: ((context, index) => Dismissible(
              onDismissed: (direction) {
                _removeItem(_goceryItems[index]);
              },
              key: ValueKey(_goceryItems[index].id),
              child: ListTile(
                title: Text(_goceryItems[index].name),
                leading: Container(
                  height: 24,
                  width: 24,
                  color: _goceryItems[index].category.color,
                ),
                trailing: Text(
                  _goceryItems[index].quantity.toString(),
                ),
              ),
            )),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Grocery List'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(
              Icons.add,
            ),
          )
        ],
      ),
      body: content,
    );
  }
}
