import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tourism AI',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Tourism AI'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String apiResponse = 'No response yet';

  final TextEditingController _controller = TextEditingController();

  Future<String> fetchAPIResponse(String prompt) async {
  const url = 'https://api.openai.com/v1/chat/completions';
  final apiKey = dotenv.env['API_KEY'];
  try {
    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey'
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "user",
            "content": prompt
          }
        ],
        "temperature": 1,
        "max_tokens": 256,
        "top_p": 1,
        "frequency_penalty": 0,
        "presence_penalty": 0
      }),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      // More detailed error information
      return 'Failed to get data: ${response.statusCode}, Body: ${response.body}';
    }
  } catch (e) {
    return 'Failed to load data: $e';
  }
 
}



  

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(

          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your prompt',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                var response = await fetchAPIResponse(_controller.text);
                setState(() {
                  apiResponse = response;
                });
              },
              child: Text('Submit')
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
              child: Text(
                  '$apiResponse'), // Add 'child:' here
            ),
            
            
          ],
        ),
      ),
      
    );
  }
  @override
  void dispose() {
    _controller.dispose();  // Clean up the controller when the widget is disposed.
    super.dispose();
  }
}


