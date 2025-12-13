import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merchant App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MerchantApp(),
    );
  }
}

class MerchantApp extends StatefulWidget {
  const MerchantApp({super.key});

  @override
  State<MerchantApp> createState() => _MerchantAppState();
}

class _MerchantAppState extends State<MerchantApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeTab(),
          AnalyticsTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============ HOME TAB ============
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Business> businesses = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:4000/api/business'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          businesses = data.map((b) => Business.fromJson(b)).toList();
        });
      }
    } catch (e) {
      print('Error loading businesses: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Businesses'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : businesses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "You haven't added any businesses yet.",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    final business = businesses[index];
                    return ListTile(
                      title: Text(business.displayName),
                      subtitle: Text(business.paymentType),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                QRDisplayScreen(business: business),
                          ),
                        ).then((_) => _loadBusinesses());
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBusinessScreen(),
            ),
          ).then((_) => _loadBusinesses());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


// ============ ANALYTICS TAB ============
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Total Transactions: —'),
                    const SizedBox(height: 16),
                    const Text('Total Revenue: —'),
                    const SizedBox(height: 24),
                    Text(
                      'Analytics will be available in a future version.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ PROFILE TAB ============
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Icon(
              Icons.account_circle,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Merchant Name'),
            subtitle: const Text('Demo Merchant'),
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ CREATE BUSINESS SCREEN ============
class CreateBusinessScreen extends StatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  State<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<CreateBusinessScreen> {
  int _currentStep = 0;
  final _displayNameController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedPaymentType = 'pochi';
  final _paymentDetailsControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    _displayNameController.dispose();
    _messageController.dispose();
    _paymentDetailsControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _createBusiness() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/business'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'displayName': _displayNameController.text,
          'message': _messageController.text,
          'paymentType': _selectedPaymentType,
          'paymentDetails': _paymentDetailsControllers.map(
            (key, controller) => MapEntry(key, controller.text),
          ),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRDisplayScreen(
                business: Business(
                  id: data['id'],
                  displayName: data['displayName'],
                  message: data['message'],
                  paymentType: data['paymentType'],
                  qrUrl: data['qrUrl'],
                  qrImage: data['qrImage'],
                ),
              ),
            ),
          ).then((_) => Navigator.pop(context));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Business'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _createBusiness();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        steps: [
          Step(
            title: const Text('Business Details'),
            content: Column(
              children: [
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    hintText: "e.g., Mary's Mangoes",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (Optional)',
                    hintText: 'e.g., Fresh mangoes daily',
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Payment Type'),
            content: Column(
              children: [
                const Text('Select the M-Pesa payment method:'),
                const SizedBox(height: 16),
                RadioListTile(
                  title: const Text('Pochi la Biashara'),
                  value: 'pochi',
                  groupValue: _selectedPaymentType,
                  onChanged: (value) {
                    setState(() => _selectedPaymentType = value!);
                  },
                ),
                RadioListTile(
                  title: const Text('Paybill'),
                  value: 'paybill',
                  groupValue: _selectedPaymentType,
                  onChanged: (value) {
                    setState(() => _selectedPaymentType = value!);
                  },
                ),
                RadioListTile(
                  title: const Text('Till Number'),
                  value: 'till',
                  groupValue: _selectedPaymentType,
                  onChanged: (value) {
                    setState(() => _selectedPaymentType = value!);
                  },
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Payment Details'),
            content: _buildPaymentDetailsForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsForm() {
    switch (_selectedPaymentType) {
      case 'pochi':
        return Column(
          children: [
            TextField(
              controller: _paymentDetailsControllers.putIfAbsent(
                'phone',
                () => TextEditingController(),
              ),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+254...',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your phone number will not be shown to customers.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      case 'paybill':
        return Column(
          children: [
            TextField(
              controller: _paymentDetailsControllers.putIfAbsent(
                'paybill',
                () => TextEditingController(),
              ),
              decoration: const InputDecoration(
                labelText: 'Paybill Number',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _paymentDetailsControllers.putIfAbsent(
                'account',
                () => TextEditingController(),
              ),
              decoration: const InputDecoration(
                labelText: 'Account Number',
              ),
            ),
          ],
        );
      case 'till':
        return TextField(
          controller: _paymentDetailsControllers.putIfAbsent(
            'till',
            () => TextEditingController(),
          ),
          decoration: const InputDecoration(
            labelText: 'Till Number',
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ============ QR DISPLAY SCREEN ============
class QRDisplayScreen extends StatelessWidget {
  final Business business;

  const QRDisplayScreen({super.key, required this.business});

  Future<void> _openCustomerPage() async {
    final url = business.qrUrl;
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  business.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(business.paymentType),
                ),
                const SizedBox(height: 32),
                if (business.qrImage != null)
                  Image.network(
                    business.qrImage!,
                    width: 250,
                    height: 250,
                  ),
                const SizedBox(height: 32),
                SelectableText(
                  business.qrUrl ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _openCustomerPage,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open Customer Page'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Businesses'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ MODELS ============
class Business {
  final String id;
  final String displayName;
  final String message;
  final String paymentType;
  final String? qrUrl;
  final String? qrImage;

  Business({
    required this.id,
    required this.displayName,
    required this.message,
    required this.paymentType,
    this.qrUrl,
    this.qrImage,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      displayName: json['displayName'],
      message: json['message'] ?? '',
      paymentType: json['paymentType'] ?? 'pochi',
    );
  }
}