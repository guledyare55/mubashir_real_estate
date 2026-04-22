import 'package:flutter/material.dart';
import 'main_admin.dart' as admin;

/// This is the primary entry point for the application.
/// It has been redirected to [admin.main()] to ensure that Windows builds
/// and installers correctly launch the Admin Portal by default,
/// preventing the default Flutter demo page from appearing.
void main() async {
  await admin.main();
}
