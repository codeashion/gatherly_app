import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'event_user_list_page.dart'; // Import the EventUserListPage

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  List<dynamic> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken') ?? '';
      final response = await http.get(
        Uri.parse(
          'https://gatherly-dyco.onrender.com/api/profile/totalCreatedEvent',
        ),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> events = data['Events'] ?? [];
        // Sort events by date ascending
        events.sort((a, b) {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2100);
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2100);
          return dateA.compareTo(dateB);
        });
        setState(() {
          _events = events;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load events';
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

  // Skeleton shimmer widget
  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 24, width: 180, color: Colors.grey),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(height: 24, width: 60, color: Colors.grey),
                      const Spacer(),
                      Container(height: 20, width: 40, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(height: 20, width: 80, color: Colors.grey),
                      const Spacer(),
                      Container(height: 20, width: 80, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(height: 20, width: 80, color: Colors.grey),
                      const Spacer(),
                      Container(height: 20, width: 80, color: Colors.grey),
                    ],
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
  Widget build(BuildContext context) {
    if (_loading) {
      // Show shimmer skeletons while loading
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_events.isEmpty) {
      return const Center(child: Text('No events found.'));
    }
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchEvents,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => EventUserListPage(
                              eventId: event['_id'],
                              eventTitle: event['title'] ?? 'Event Users',
                            ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: Image.network(
                            event['banner'] ?? '',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  height: 180,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 48),
                                  ),
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(event['category'] ?? ''),
                                    backgroundColor: Colors.deepPurple.shade50,
                                    labelStyle: const TextStyle(
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹${event['price'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Capacity: ${event['capacity'] ?? ''}'),
                                  const Spacer(),
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(event['venue'] ?? ''),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event['date'] != null
                                        ? event['date'].substring(0, 10)
                                        : '',
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(event['time'] ?? ''),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 70),
      ],
    );
  }
}
