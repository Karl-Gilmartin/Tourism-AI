

import 'package:flutter/material.dart';

class ResponsePage extends StatelessWidget {
  const ResponsePage({Key? key, required this.apiResponse}) : super(key: key);

  final String apiResponse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Response'),
      ),
      body: Center(
        child: Text(apiResponse),
      ),
    );
  }
}