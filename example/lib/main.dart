/*
==========================================================
🧩 Example App — DioX Dio - Extended
==========================================================

This is a **simple example** demonstrating how to use the `dio_extended` library.

🎯 Purpose:
Show how to perform basic CRUD (Create, Read, Update, Delete) operations
using the extended Dio service (`BaseDioServices`) and a Freezed data model (`PostModel`).

📚 Features demonstrated:
- GET: Display a list of posts from an API.
- POST: Add a new post using the FloatingActionButton.
- DELETE: Remove a post using the delete icon in each ListTile.
- ApiResult usage for success/failure response handling.

🌐 API endpoint used:
https://jsonplaceholder.typicode.com/posts

💡 To run this example:
flutter run -t example/lib/main.dart

Or, if using VS Code:
Press F5 and select the “Run Example App” configuration.

==========================================================
*/

import 'package:dio_extended/diox.dart';
import 'package:example/statemanagement/origin/statefull_post_page_view.dart';
import 'package:flutter/material.dart';

void main() {
  ShakeChuckerConfigs.initialize(
    showOnRelease: false,
    showNotification: false,
  );
  runApp(
    ShakeForChucker(
      child: MaterialApp(
        title: 'DioX (Dio Extended) Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        home: const StatefullPostPageView(),
        navigatorObservers: [
          ShakeChuckerConfigs.navigatorObserver,
        ],
      ),
    ),
  );
}
