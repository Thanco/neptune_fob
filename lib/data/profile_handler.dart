import 'package:flutter/material.dart';
import 'package:neptune_fob/data/profile.dart';

class ProfileHandler with ChangeNotifier {
  static final ProfileHandler _instance = ProfileHandler._constructor();
  final Map<String, Profile> _profiles = {};
  Map<String, Profile> get profiles => _profiles;

  ProfileHandler._constructor();
  factory ProfileHandler() {
    return _instance;
  }

  void addProfiles(List<Profile> newProfiles) {
    for (Profile profile in newProfiles) {
      profiles.addAll({profile.userName: profile});
    }
    notifyListeners();
  }
}
