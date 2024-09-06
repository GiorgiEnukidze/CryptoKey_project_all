import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';


class StatisticsPage extends StatefulWidget {
  final String token;

  StatisticsPage({required this.token});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Map<String, dynamic>? _statistics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchStatistics();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/statistics/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _statistics = json.decode(response.body);
        });
        print('Statistics data: $_statistics');
      } else {
        print('Failed to load statistics, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Statistics',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.0),
                  if (_statistics != null) ...[
                    Text('Total Users: ${_statistics!['total_users']}'),
                    Text('Latest User Joined: ${_formatDate(_statistics!['latest_user_joined'])}'),
                    Text('User Activity (Last 30 days): ${_statistics!['user_activity']}'),
                  ],
                  SizedBox(height: 16.0),
                  Text(
                    'User List',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_statistics != null)
                    ..._statistics!['users'].map<Widget>((user) {
                      return ListTile(
                        title: Text(user['username']),
                        subtitle: Text('Joined: ${_formatDate(user['date_joined'])}\nLast Login: ${user['last_login'] != null ? _formatDate(user['last_login']) : 'Never'}'),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }

  String _formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
  }
}
