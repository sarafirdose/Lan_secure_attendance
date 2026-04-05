import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final users = prefs.getStringList('sa_backend_users') ?? [];
  
  if (users.isEmpty) {
    print('NO_USERS_FOUND');
  } else {
    print('--- SEEDED USERS ---');
    for (var u in users) {
      final user = jsonDecode(u);
      print('Role: ${user['role']} | ID: ${user['id']} | Name: ${user['name']}');
    }
    print('--------------------');
  }
}
