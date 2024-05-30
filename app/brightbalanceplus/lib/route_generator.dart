import 'package:brightbalanceplus/profile_room_preferences.dart';
import 'package:brightbalanceplus/profiles.dart';
import 'package:brightbalanceplus/register.dart';
import 'package:flutter/material.dart';
import 'Dao/profile.dart';
import 'Dao/room.dart';
import 'create_profile.dart';
import 'create_room.dart';
import 'edit_profile.dart';
import 'edit_room.dart';
import 'error_route.dart';
import 'house_rooms.dart';
import 'main.dart';

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