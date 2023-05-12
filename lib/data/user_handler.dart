// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';

class UserHandler with ChangeNotifier {
  static final UserHandler _instance = UserHandler._constructor();
  final List<String> _userList = [];

  List<String> get userList => _userList;

  factory UserHandler() {
    return _instance;
  }
  UserHandler._constructor();

  void addUser(String userName) {
    if (!_userList.contains(userName)) {
      _userList.add(userName);
    }
    notifyListeners();
  }

  void addUsers(List<String> userNames) {
    _userList.addAll(userNames);
    notifyListeners();
  }

  void removeUser(String userName) {
    _userList.remove(userName);
    notifyListeners();
  }

  void clearUsers() {
    _userList.clear();
    notifyListeners();
  }
}
