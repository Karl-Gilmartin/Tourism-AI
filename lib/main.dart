import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:multi_dropdown/multiselect_dropdown.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tourist_ai/response.dart';

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
  String _locationMessage = "";


  String getSelectedOptions() {
    return _selectedOptions.map((item) => item.label).join(", ");
  }

  String getHolidayPurpose() {
  return _counter == 1 ? "Pleasure" : "Business";
}


  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _locationMessage = "${position.latitude}, ${position.longitude}";
    });
  }

  final MultiSelectController _controllerMultiSelect = MultiSelectController();

  final List<ValueItem> _selectedOptions = [];

  final TextEditingController _controller = TextEditingController();

  Future<String> fetchAPIResponse(String prompt ) async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String selectedOptions = getSelectedOptions();
    String holidayPurpose = getHolidayPurpose();

    String RAG_prompt = ("I am currently on in $prompt, I would like to see some tourism sites. Can you suggest some places to visit? I am interested in $selectedOptions .I am on holiday for $holidayPurpose. The date is $date.");
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
            {"role": "user", "content": prompt}
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
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your prompt',
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 00),
              child: MultiSelectDropDown(
                showClearIcon: true,
                controller: _controllerMultiSelect,
                onOptionSelected: (options) {
                  debugPrint(options.toString());
                },
                options: const <ValueItem>[
                  ValueItem(label: 'History', value: 'History'),
                  ValueItem(label: 'Architecture', value: 'Architecture'),
                  ValueItem(label: 'Family', value: 'Family'),
                  ValueItem(label: 'Culture', value: 'Culture'),
                  ValueItem(label: 'Shopping', value: 'Shopping'),
                ],
                // disabledOptions: const [ValueItem(label: 'History', value: '1')],
                selectionType: SelectionType.multi,
                chipConfig: const ChipConfig(wrapType: WrapType.wrap),
                dropdownHeight: 300,
                optionTextStyle: const TextStyle(fontSize: 16),
                selectedOptionIcon: const Icon(Icons.check_circle),
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  var response = await fetchAPIResponse(_controller.text);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResponsePage(apiResponse: response),
                    ),
                  );
                  setState(() {
                    apiResponse = response;
                  });
                },
                child: Text('Submit')),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Pleasure'),
                    leading: Radio<int>(
                      value: 1,
                      groupValue: _counter,
                      onChanged: (int? value) {
                        setState(() {
                          if (value != null) {
                            _counter = value;
                          }
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Business'),
                    leading: Radio<int>(
                      value: 2,
                      groupValue: _counter,
                      onChanged: (int? value) {
                        setState(() {
                          if (value != null) {
                            _counter = value;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Current Date Time show
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Current Date Time'),
                    subtitle: Text(formattedDate),
                  ),
                ],
              ),
            ),
            // Location
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text(_locationMessage),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: Text("Find Location"), 
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Clean up the controller when the widget is disposed.
    super.dispose();
  }
}
