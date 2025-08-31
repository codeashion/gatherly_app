import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventUserListPage extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  const EventUserListPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventUserListPage> createState() => _EventUserListPageState();
}

class _EventUserListPageState extends State<EventUserListPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUserList();
  }

  Future<void> _fetchUserList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken') ?? '';
      final response = await http.get(
        Uri.parse(
          'https://gatherly-dyco.onrender.com/api/events/userList/${widget.eventId}',
        ),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = data['userDetails'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load user list';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        title: Text(
          widget.eventTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 8,
        centerTitle: true,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : _users.isEmpty
              ? const Center(child: Text('No registered users found.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final attended =
                      user['attend'] ?? false; // <-- handle missing key
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: attended ? Colors.green : Colors.red,
                        child: Icon(
                          attended ? Icons.check : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        user['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user['email'] ?? ''),
                      trailing: Chip(
                        label: Text(attended ? 'Attended' : 'Not Attended'),
                        backgroundColor:
                            attended
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                        labelStyle: TextStyle(
                          color: attended ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
