import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:never_have_i_ever/models/category.dart';
import 'package:never_have_i_ever/models/statement.dart';

class StatementApiProvider {
  /// Returns `Future<Statement>` from https://api.neverhaveiever.io/v1/statement based on [categories].
  ///
  /// If no `Category` in [categories] is selected this function returns a `Statement` with text: 'Please select a category to continue'.
  static Future<Statement> fetchStatement(List<Category> categories) async {
    if (categories.every((category) => !category.selected)) {
      return Statement(text: 'Please select a category to continue');
    }

    String params = categories
        .map((category) => '${category.name}=${category.selected}')
        .join('&');

    final response =
        await http.get('https://api.neverhaveiever.io/v1/statement?$params');

    if (response.statusCode == 200) {
      return Statement.fromJson(response.body);
    } else {
      return null;
    }
  }
}
