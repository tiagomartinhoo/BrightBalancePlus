import 'package:brightbalance/create_room.dart';
import 'package:brightbalance/edit_room.dart';
import 'package:brightbalance/house_rooms.dart';
import 'package:brightbalance/profile_room_preferences.dart';
import 'package:brightbalance/profiles.dart';
import 'package:flutter/material.dart';
import 'package:brightbalance/main.dart';
import 'package:brightbalance/register.dart';
import 'package:brightbalance/error_route.dart';
import 'package:brightbalance/create_profile.dart';
import 'package:brightbalance/edit_profile.dart';

import 'Dao/profile.dart';
import 'Dao/room.dart';

class RouteGenerator
{
  static Route<dynamic> generateRoute(RouteSettings settings){

    final args = settings.arguments;

    switch(settings.name){
      case '/':
        return MaterialPageRoute(builder: (_) => const Login());
      case '/register':
        return MaterialPageRoute(builder: (_) => const Register());
      case '/profiles':
        return MaterialPageRoute(builder: (_) => const Profiles());
      case '/create_profile':
        return MaterialPageRoute(builder: (_) => const CreateProfile());
      case '/edit_profile':
        if(args is Profile) {
          return MaterialPageRoute(builder: (_) => EditProfile(data: args));
        }
        break;
      case '/house_rooms':
        return MaterialPageRoute(builder: (_) => HouseRooms(data: args.toString()));
      case '/create_room':
        return MaterialPageRoute(builder: (_) => CreateRoom(data: args.toString()));
      case '/edit_room':
        if(args is Room) {
          return MaterialPageRoute(builder: (_) => EditRoom(data: args));
        }
        break;
      case '/profile_room_preferences':
        if(args is Room) {
          return MaterialPageRoute(builder: (_) => ProfileRoomPreferences(data: args));
        }
        break;
    }

    return MaterialPageRoute(builder: (_) => const ErrorRoute());
  }

}