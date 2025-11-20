import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// -----------------------------------------------------------------------------
// 1. DOMAIN LAYER (Entities & Contracts)
// -----------------------------------------------------------------------------

/// Entity: Represents a food item listed for donation.
class FoodItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime expiryDate;
  final LatLng location;
  final String donorName;
  final bool isAvailable;

  FoodItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.expiryDate,
    required this.location,
    required this.donorName,
    this.isAvailable = true,
  });
}

/// Repository Interface: Defines the contract for data operations.
abstract class FoodRepository {
  Future<List<FoodItem>> getNearbyFood(LatLng userLocation, double radiusKm);
  Future<void> donateFood(FoodItem item);
  Future<void> requestFood(String itemId);
}

// -----------------------------------------------------------------------------
// 2. DATA LAYER (Implementation & Mocks)
// -----------------------------------------------------------------------------

/// Mock Implementation: Simulates a Supabase/Database connection.
class MockFoodRepository implements FoodRepository {
  // Simulating a database in memory
  final List<FoodItem> _mockDatabase = [
    FoodItem(
      id: '1',
      title: 'Surprise Bag - Bakery',
      description: 'Assorted pastries and bread from today.',
      imageUrl: 'https://via.placeholder.com/150',
      expiryDate: DateTime.now().add(const Duration(hours: 24)),
      location: const LatLng(-1.2921, 36.8219), // Nairobi CBD
      donorName: 'City Bakery',
    ),
    FoodItem(
      id: '2',
      title: 'Vegetable Stew',
      description: '5 servings of fresh stew. Vegetarian.',
      imageUrl: 'https://via.placeholder.com/150',
      expiryDate: DateTime.now().add(const Duration(hours: 5)),
      location: const LatLng(-1.2864, 36.8172), // Near University
      donorName: 'Mama Oliech Restaurant',
    ),
    FoodItem(
      id: '3',
      title: 'Fresh Fruit Box',
      description: 'Bananas and Mangoes, slightly ripe.',
      imageUrl: 'https://via.placeholder.com/150',
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      location: const LatLng(-1.2990, 36.7800), // Kilimani area
      donorName: 'Green Grocers',
    ),
  ];

  @override
  Future<List<FoodItem>> getNearbyFood(
    LatLng userLocation,
    double radiusKm,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 800),
    ); // Simulate network latency
    return _mockDatabase.where((item) => item.isAvailable).toList();
  }

  @override
  Future<void> donateFood(FoodItem item) async {
    await Future.delayed(const Duration(seconds: 1));
    // Insert at the beginning of the list so it shows up first
    _mockDatabase.insert(0, item);
  }

  @override
  Future<void> requestFood(String itemId) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockDatabase.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      // Create a copy with isAvailable = false
      final original = _mockDatabase[index];
      _mockDatabase[index] = FoodItem(
        id: original.id,
        title: original.title,
        description: original.description,
        imageUrl: original.imageUrl,
        expiryDate: original.expiryDate,
        location: original.location,
        donorName: original.donorName,
        isAvailable: false,
      );
    }
  }
}

// -----------------------------------------------------------------------------
// 3. PRESENTATION LAYER (State Management - Riverpod)
// -----------------------------------------------------------------------------

// Providers
final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => MockFoodRepository(),
);

// This provider fetches the list of food. We can refresh it to see new items.
final foodListProvider = FutureProvider<List<FoodItem>>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  // Mocking user location (Nairobi)
  return repository.getNearbyFood(const LatLng(-1.2921, 36.8219), 5.0);
});

// A simple StateNotifier to handle the user's active role (Donor vs Receiver)
class UserRoleNotifier extends StateNotifier<String> {
  UserRoleNotifier() : super('Receiver'); // Default role
  void toggleRole() => state = state == 'Receiver' ? 'Donor' : 'Receiver';
}

final userRoleProvider = StateNotifierProvider<UserRoleNotifier, String>(
  (ref) => UserRoleNotifier(),
);

// -----------------------------------------------------------------------------
// 4. USER INTERFACE (Widgets & Screens)
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: ZeroHungerApp()));
}

class ZeroHungerApp extends StatelessWidget {
  const ZeroHungerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zero Hunger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const MainNavigationWrapper(),
    );
  }
}

class MainNavigationWrapper extends ConsumerStatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  ConsumerState<MainNavigationWrapper> createState() =>
      _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends ConsumerState<MainNavigationWrapper> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);

    final List<Widget> pages = [
      const HomeMapScreen(),
      if (userRole == 'Donor')
        const DonateFoodScreen()
      else
        const RequestsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Rescue Map',
          ),
          NavigationDestination(
            icon: Icon(
              userRole == 'Donor' ? Icons.add_circle_outline : Icons.list_alt,
            ),
            selectedIcon: Icon(
              userRole == 'Donor' ? Icons.add_circle : Icons.list,
            ),
            label: userRole == 'Donor' ? 'Donate' : 'Requests',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --- Screen 1: Home Map (The "Rescue Map") ---

class HomeMapScreen extends ConsumerWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodListAsync = ref.watch(foodListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zero Hunger Map'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(foodListProvider),
          ),
        ],
      ),
      body: foodListAsync.when(
        data: (foodItems) {
          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-1.2921, 36.8219), // Nairobi
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.zero_hunger_app',
                  ),
                  MarkerLayer(
                    markers: foodItems.map((item) {
                      return Marker(
                        point: item.location,
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _showFoodDetails(context, item, ref),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 50,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              // Floating Card at bottom
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.fastfood, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${foodItems.length} surplus meals available nearby.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading map: $err')),
      ),
    );
  }

  void _showFoodDetails(BuildContext context, FoodItem item, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                color: Colors.grey[300],
                margin: const EdgeInsets.only(bottom: 20),
              ),
            ),
            Text(
              item.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item.donorName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Text(item.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orange),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Expires By",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(item.expiryDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Trigger request logic
                  ref.read(foodRepositoryProvider).requestFood(item.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Success! Pickup details sent to your inbox.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh map
                  ref.refresh(foodListProvider);
                },
                icon: const Icon(Icons.handshake),
                label: const Text(
                  'REQUEST PICKUP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- Screen 2: Donate Food (For Donors) ---

class DonateFoodScreen extends ConsumerStatefulWidget {
  const DonateFoodScreen({super.key});

  @override
  ConsumerState<DonateFoodScreen> createState() => _DonateFoodScreenState();
}

class _DonateFoodScreenState extends ConsumerState<DonateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newItem = FoodItem(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descController.text,
      imageUrl: '',
      expiryDate: DateTime.now().add(const Duration(hours: 24)),
      location: const LatLng(-1.2921, 36.8219), // Mock current location
      donorName: 'My Restaurant',
    );

    await ref.read(foodRepositoryProvider).donateFood(newItem);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation Posted Successfully!')),
      );
      _titleController.clear();
      _descController.clear();
      // Force refresh of the list so the map updates when we go back
      ref.refresh(foodListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate Surplus Food')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to take photo of food'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Item Title',
                  hintText: 'e.g., 10x Bagels, 2kg Rice',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description & Quantity',
                  hintText: 'Describe the condition and amount...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _submitDonation,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text(
                        'POST DONATION',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Screen 3: Requests List (For Receivers) ---

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pickups')),
      body: ListView.builder(
        itemCount: 1,
        padding: const EdgeInsets.all(16),
        itemBuilder: (ctx, index) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white),
              ),
              title: const Text('Vegetable Stew'),
              subtitle: const Text('Confirmed - Pickup by 5:00 PM'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}

// --- Screen 4: Profile (Role Switcher & Settings) ---

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            accountName: Text(
              "Active User",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text("user@zerohunger.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.green),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "APP MODE",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Donor Mode (Restaurant)'),
            subtitle: const Text('Switch on to post food'),
            value: currentRole == 'Donor',
            secondary: const Icon(Icons.storefront),
            activeColor: Colors.green,
            onChanged: (_) => ref.read(userRoleProvider.notifier).toggleRole(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.green),
            title: const Text('Support Zero Hunger'),
            subtitle: const Text('Donate via M-Pesa'),
            onTap: () => _simulateMpesaPayment(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _simulateMpesaPayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.monetization_on, color: Colors.green),
            SizedBox(width: 10),
            Text('M-Pesa STK Push'),
          ],
        ),
        content: const Text(
          'Simulating STK Push to 2547XXXXXXXX...\n\nPlease enter your PIN on your phone to complete the donation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
