// Copyright Terry Hancock 2023
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/data/user_handler.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  // void addUser(String userName) {
  //   if (!UserHandler().userList.contains(userName)) {
  //     UserHandler().addUser(userName);
  //     setState(() {});
  //   }
  // }

  // void addUsers(List<String> userNames) {
  //   UserHandler().addUsers(userNames);
  //   setState(() {});
  // }

  // void removeUser(String userName) {
  //   UserHandler().removeUser(userName);
  //   setState(() {});
  // }

  // void clearUsers() {
  //   UserHandler().clearUsers();
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserHandler>(
      builder: (context, userHandler, child) {
        return ListView.separated(
          itemCount: userHandler.userList.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (BuildContext context, int index) {
            return Consumer<TextStyleHandler>(
              builder: (context, textStyleHandler, child) {
                return Text(
                  userHandler.userList[index],
                  style: TextStyle(
                    fontFamily: textStyleHandler.font,
                    fontSize: textStyleHandler.fontSize * 0.64,
                  ),
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  softWrap: false,
                );
              },
            );
          },
        );
      },
    );
  }
}
