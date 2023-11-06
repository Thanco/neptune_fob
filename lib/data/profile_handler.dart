import 'package:flutter/material.dart';
import 'package:neptune_fob/data/profile.dart';

class ProfileHandler with ChangeNotifier {
  static final ProfileHandler _instance = ProfileHandler._constructor();
  final Map<String, Profile> _profileBucket = {};
  final Map<String, dynamic> _profiles = {};
  Map<String, dynamic> get sortedProfiles => _profiles;

  ProfileHandler._constructor();
  factory ProfileHandler() {
    return _instance;
  }

  void addProfiles(List<Profile> newProfiles) {
    for (Profile profile in newProfiles) {
      _profileBucket.addAll({profile.userName.split("/").last: profile});
    }
    for (var profile in newProfiles) {
      final split = profile.userName.split("/");
      createNextObject(_profiles, profile, split, 0);
    }
    notifyListeners();
  }

  dynamic createNextObject(Map<String, dynamic> folder, Profile profile, List<String> split, int depth) {
    if (split.length - 1 <= depth) {
      folder.addAll({profile.userName: profile});
      return;
    }
    final Map<String, dynamic> newFolder = {};
    var newFolderName = "";
    for (var i = 0; i <= depth; i++) {
      newFolderName += "${split[i]}/";
    }
    if (folder.containsKey(newFolderName)) {
      createNextObject(folder[newFolderName], profile, split, depth + 1);
      return;
    }
    folder.addAll({newFolderName: newFolder});
    createNextObject(newFolder, profile, split, depth + 1);
  }

  Profile? getProfile(String userName) {
    return _profileBucket[userName];
  }

  void removeProfile(String userName) {
    _profileBucket.remove(userName);
    for (var element in _profiles.entries) {
      if (element.key == userName) {
        _profiles.remove(element.key);
        break;
      } else if (element.key.endsWith("/")) {
        _removeProfile(userName, element.value);
      }
    }
  }

  void _removeProfile(String userName, Map<String, dynamic> folder) {
    final items = folder.entries.toList();
    for (var i = 0; i < folder.entries.length; i++) {
      if (items[i].key.split("/").last == userName) {
        folder.remove(items[i].key);
        break;
      } else if (items[i].key.endsWith("/")) {
        _removeProfile(userName, items[i].value);
      }
    }
  }

  void removeFolder(String name) {
    for (var element in _profiles.entries) {
      if (element.key == name) {
        _profiles.remove(element.key);
      } else if (element.key.endsWith("/")) {
        _removeFolder(name, element.value);
      }
    }
  }

  void _removeFolder(String name, Map<String, dynamic> folder) {
    for (var element in _profiles.entries) {
      if (element.key == name) {
        folder.remove(element.key);
        return;
      } else if (element.key.endsWith("/")) {
        _removeProfile(name, element.value);
      }
    }
  }
}
