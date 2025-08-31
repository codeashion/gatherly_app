import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  bool _hasScanned = false;
  late AnimationController _glowController;
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scannerController = MobileScannerController(autoZoom: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture result) async {
    if (!_hasScanned && result.barcodes.isNotEmpty) {
      setState(() {
        _hasScanned = true;
      });
      _scannerController.stop();

      for (final barcode in result.barcodes) {
        final raw = barcode.rawValue;
        if (raw != null) {
          final regExp = RegExp(
            r'UserID:\s*([a-zA-Z0-9]+),\s*EventID:\s*([a-zA-Z0-9]+)',
          );
          final match = regExp.firstMatch(raw);
          if (match != null) {
            final userId = match.group(1);
            final eventId = match.group(2);
            print('UserID: $userId');
            print('EventID: $eventId');

            // Call the PATCH API
            try {
              final prefs = await SharedPreferences.getInstance();
              final jwtToken = prefs.getString('jwtToken') ?? '';
              final response = await http.patch(
                Uri.parse(
                  'https://gatherly-dyco.onrender.com/api/booking/userAttend/$eventId',
                ),
                headers: {
                  'Authorization': 'Bearer $jwtToken',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'userId': userId}),
              );
              print('Attend API response: ${response.body}');
            } catch (e) {
              print('Attend API error: $e');
            }
          } else {
            print('Invalid QR data: $raw');
          }
        }
      }

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('QR Scanned'),
              content: Text(
                'QR successfully scanned:\n${result.barcodes.first.rawValue ?? "No data"}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _hasScanned = false;
                      _scannerController.start();
                    });
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Blurred background image
          SizedBox.expand(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Image.asset(
                'assets/images/scann_back.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(color: Colors.black.withOpacity(0.4)),
          // Instructions
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Text(
                  'Scan QR inside the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Scanning will start automatically',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          // Scanner frame with glow animation
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(
                        0.5 + 0.5 * _glowController.value,
                      ),
                      blurRadius: 24 + 12 * _glowController.value,
                      spreadRadius: 2 + 2 * _glowController.value,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
