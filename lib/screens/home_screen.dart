import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/service_provider.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isGridView = false;
  bool isLoading = true;

  List<ServiceProvider> providers = [];
  List<ServiceProvider> filteredProviders = [];

  @override
  void initState() {
    super.initState();
    fetchProviders();
  }

  // 🔥 FETCH API
  Future<void> fetchProviders() async {
    try {
      setState(() => isLoading = true);

      final response = await http.get(
        Uri.parse('https://69b8f492e69653ffe6a601eb.mockapi.io/api/v1/providers'),
      );

      if (response.statusCode == 200) {
        List data = json.decode(response.body);

        setState(() {
          providers = data.map((e) => ServiceProvider.fromJson(e)).toList();
          filteredProviders = providers;
        });
      } else {
        _showMessage("Failed to load data");
      }
    } catch (e) {
      _showMessage("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔍 SEARCH
  void _search(String value) {
    setState(() {
      filteredProviders = providers
          .where((p) =>
      p.name.toLowerCase().contains(value.toLowerCase()) ||
          p.category.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  // 🚪 LOGOUT
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // 📞 CALL
  Future<void> _call() async {
    final Uri uri = Uri(scheme: 'tel', path: '1234567890');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showMessage("Cannot launch dialer");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "MyCityConnect",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          )
        ],
      ),

      // 🔥 DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.deepPurpleAccent,
              ),
              accountName: const Text(
                "Welcome",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? "Guest User"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.deepPurpleAccent, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: Colors.deepPurple),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.book_rounded, color: Colors.deepPurple),
              title: const Text("My Bookings"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Colors.deepPurple),
              title: const Text("Profile"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.phone_rounded, color: Colors.deepPurple),
              title: const Text("Contact Us"),
              onTap: _call,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
          ],
        ),
      ),

      // 🔄 BODY
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: _search,
              decoration: InputDecoration(
                hintText: "Search services...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.deepPurpleAccent),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
                : filteredProviders.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No Data Found",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: Colors.deepPurpleAccent,
              onRefresh: fetchProviders,
              child: isGridView ? _buildGrid() : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  // 📋 LIST VIEW
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredProviders.length,
      itemBuilder: (context, index) {
        final p = filteredProviders[index];

        return Card(
          elevation: 3,
          shadowColor: Colors.deepPurple.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                p.imageUrl,
                width: 65,
                height: 65,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 65,
                  height: 65,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0), // <-- Fixed Typo Here
              child: Row(
                children: [
                  Text(
                    p.category,
                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  Text(
                    " ${p.rating}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailsScreen(provider: p),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 🔲 GRID VIEW
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredProviders.length,
      itemBuilder: (context, index) {
        final p = filteredProviders[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailsScreen(provider: p),
              ),
            );
          },
          child: Card(
            elevation: 3,
            shadowColor: Colors.deepPurple.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              Text(
                                "${p.rating}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
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
    );
  }
}