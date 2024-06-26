import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings.dart';
import 'add_password.dart';
import 'password_details.dart';
import 'folder_page.dart';

class HomePage extends StatefulWidget {
  final int userId;

  HomePage({required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _folders = [];
  List<dynamic> _recentPasswords = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchFolders();
    await _fetchRecentPasswords();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchFolders() async {
    final response = await http.post(
      Uri.parse('http://taylorv24.sg-host.com/get_folders.php'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'userId': widget.userId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _folders = json.decode(response.body);
      });
    } else {
      setState(() {
        _folders = [];
      });
    }
  }

  Future<void> _fetchRecentPasswords() async {
    final response = await http.post(
      Uri.parse('http://taylorv24.sg-host.com/get_recent_passwords.php'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'userId': widget.userId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _recentPasswords = json.decode(response.body);
      });
    } else {
      setState(() {
        _recentPasswords = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('SecuroScanner'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            // Home page is already selected
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          } else if (index == 2) {
            // Handle QR code page navigation here
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR Code'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPasswordPage(userId: widget.userId)),
          );
          if (result == true) {
            setState(() {
              _isLoading = true;
            });
            _fetchData(); // Refresh data
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Folders', style: Theme.of(context).textTheme.headline5),
              SizedBox(height: 10),
              _buildFolders(),
              SizedBox(height: 20),
              Text('Recent Passwords', style: Theme.of(context).textTheme.headline5),
              SizedBox(height: 10),
              _buildRecentPasswords(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolders() {
    if (_folders.isEmpty) {
      return Text('No folders available.', style: Theme.of(context).textTheme.bodyText1);
    }
    return Column(
      children: _folders.map((folder) {
        return ListTile(
          title: Text(folder['FolderName'], style: Theme.of(context).textTheme.bodyText1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FolderPage(folderId: folder['FolderID'], folderName: folder['FolderName']),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildRecentPasswords() {
    if (_recentPasswords.isEmpty) {
      return Text('No recent passwords available.', style: Theme.of(context).textTheme.bodyText1);
    }
    return Column(
      children: _recentPasswords.map((password) {
        return ListTile(
          title: Text(password['Name'], style: Theme.of(context).textTheme.bodyText1),
          subtitle: Text(password['Username'], style: Theme.of(context).textTheme.bodyText2),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PasswordDetailsPage(passwordId: password['PasswordID'])),
            );
          },
        );
      }).toList(),
    );
  }
}
