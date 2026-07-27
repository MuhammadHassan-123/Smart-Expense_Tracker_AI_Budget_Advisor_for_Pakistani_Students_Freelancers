import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'analytics_screen.dart';
import 'ai_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {

  const MainScreen({super.key});

  @override
  State<MainScreen> createState()=>_MainScreenState();

}

class _MainScreenState extends State<MainScreen>{

  int index=0;

  final screens=[

    HomeScreen(),

    const AnalyticsScreen(),

    const AiScreen(),

    const ProfileScreen(),

  ];

  @override
  Widget build(BuildContext context){

    return Scaffold(

      body:screens[index],

      bottomNavigationBar:NavigationBar(

        selectedIndex:index,

        onDestinationSelected:(value){

          setState(() {

            index=value;

          });

        },

        destinations: const [

          NavigationDestination(

            icon: Icon(Icons.home),

            label:"Home",

          ),

          NavigationDestination(

            icon: Icon(Icons.bar_chart),

            label:"Analytics",

          ),

          NavigationDestination(

            icon: Icon(Icons.auto_awesome),

            label:"AI",

          ),

          NavigationDestination(

            icon: Icon(Icons.person),

            label:"Profile",

          ),

        ],

      ),

    );

  }

}