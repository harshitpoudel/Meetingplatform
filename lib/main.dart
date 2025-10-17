import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Detect host for emulators
  String host;
  if (kIsWeb) {
    host = '127.0.0.1';
  } else if (Platform.isAndroid) {
    host = '10.0.2.2';
  } else {
    host = 'localhost';
  }

  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);

  runApp(const ProviderScope(child: RootApp()));
}

/// RootApp switches between login & app depending on auth state
class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        if (snapshot.hasData) {
          return const MyApp();
        }
        return const MaterialApp(home: LoginPage());
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meeting Platform',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// --- Home with Bottom Nav ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    UsersPage(),
    InvitationsPage(),
    MeetingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invitations')
            .where('to', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          int pendingCount =
              snapshot.hasData ? snapshot.data!.docs.length : 0;

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.people), label: 'Users'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.mail),
                    if (pendingCount > 0)
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Invites',
              ),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today), label: 'Meetings'),
            ],
          );
        },
      ),
    );
  }
}

/// --- Seed Demo Data Helper ---
Future<void> seedDemoData(BuildContext context) async {
  final fs = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final me = auth.currentUser;

  if (me == null) return;

  Future<void> ensureUser(String uid, String name, String email) async {
    final doc = await fs.collection('users').doc(uid).get();
    if (!doc.exists) {
      await fs.collection('users').doc(uid).set({
        'displayName': name,
        'email': email,
      });
    }
  }

  const demoAId = 'demoUserA';
  const demoBId = 'demoUserB';
  await ensureUser(demoAId, 'Alice', 'alice@example.com');
  await ensureUser(demoBId, 'Bob', 'bob@example.com');

  final myDoc = await fs.collection('users').doc(me.uid).get();
  if (!myDoc.exists) {
    await fs.collection('users').doc(me.uid).set({
      'displayName': (me.email ?? 'you').split('@').first,
      'email': me.email ?? 'random@example.com',
    });
  }

  await fs.collection('invitations').add({
    'from': demoAId,
    'to': me.uid,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
  await fs.collection('invitations').add({
    'from': me.uid,
    'to': demoBId,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });

  DateTime now = DateTime.now();
  await fs.collection('meetings').add({
    'participants': [me.uid, demoAId],
    'scheduledAt': Timestamp.fromDate(now.add(const Duration(hours: 2))),
  });
  await fs.collection('meetings').add({
    'participants': [me.uid, demoBId],
    'scheduledAt': Timestamp.fromDate(now.add(const Duration(days: 7))),
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Seeded demo users, invites & meetings 👍')),
  );
}

/// --- Page 1: Users ---
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usersStream =
        FirebaseFirestore.instance.collection('users').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Seed demo data',
            onPressed: () async {
              await seedDemoData(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((data['displayName'] ?? 'U')[0].toUpperCase()),
                  ),
                  title: Text(data['displayName'] ?? 'Unknown'),
                  subtitle: Text(data['email'] ?? ''),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final currentUser = FirebaseAuth.instance.currentUser!;
                      await FirebaseFirestore.instance
                          .collection('invitations')
                          .add({
                        'from': currentUser.uid,
                        'to': docs[i].id,
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    },
                    child: const Text('Invite'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// --- Page 2: Invitations with Tabs ---
class InvitationsPage extends StatelessWidget {
  const InvitationsPage({super.key});

  Future<Map<String, dynamic>?> _getUser(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invitations'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Received
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('invitations')
                  .where('to', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No received invites.'));
                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'];
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getUser(data['from']),
                      builder: (context, snap) {
                        if (!snap.hasData) return const ListTile(title: Text("Loading user..."));
                        final user = snap.data!;
                        return Card(
                          child: ListTile(
                            title: Text("From: ${user['displayName']} (${user['email']})"),
                            subtitle: Text("Status: $status"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    await doc.reference.update({'status': 'accepted'});
                                    await FirebaseFirestore.instance.collection('meetings').add({
                                      'participants': [data['from'], data['to']],
                                      'scheduledAt': FieldValue.serverTimestamp(),
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () async {
                                    await doc.reference.delete();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            // Sent
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('invitations')
                  .where('from', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No sent invites.'));
                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'];
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getUser(data['to']),
                      builder: (context, snap) {
                        if (!snap.hasData) return const ListTile(title: Text("Loading user..."));
                        final user = snap.data!;
                        return Card(
                          child: ListTile(
                            title: Text("To: ${user['displayName']} (${user['email']})"),
                            subtitle: Text("Status: $status"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await doc.reference.delete();
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// --- Page 3: Meetings ---
class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});

  Future<Map<String, dynamic>?> _getUser(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<List<String>> _getParticipantDetails(List<dynamic> uids) async {
    final List<String> details = [];
    for (var uid in uids) {
      final user = await _getUser(uid);
      if (user != null) {
        details.add("${user['displayName']} (${user['email']})");
      } else {
        details.add(uid);
      }
    }
    return details;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final meetingsStream = FirebaseFirestore.instance
        .collection('meetings')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: meetingsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No meetings yet.'));
          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final participants = List<String>.from(data['participants'] ?? []);
              final ts = data['scheduledAt'] as Timestamp?;
              return FutureBuilder<List<String>>(
                future: _getParticipantDetails(participants),
                builder: (context, snap) {
                  if (!snap.hasData) return const ListTile(title: Text("Loading..."));
                  final details = snap.data!;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.video_call, color: Colors.indigo),
                      title: Text("Participants: ${details.join(", ")}"),
                      subtitle: Text(ts != null ? "At: ${ts.toDate()}" : "At: Unknown"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await doc.reference.delete();
                        },
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// --- Page 4: Calendar ---
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  Future<Map<String, dynamic>?> _getUser(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final meetingsStream = FirebaseFirestore.instance
        .collection('meetings')
        .where('participants', arrayContains: FirebaseAuth.instance.currentUser!.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Calendar')),
      body: StreamBuilder<QuerySnapshot>(
        stream: meetingsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final meetings = snapshot.data!.docs;
          return FutureBuilder<Map<DateTime, List<String>>>(
            future: () async {
              final map = <DateTime, List<String>>{};
              for (var doc in meetings) {
                final data = doc.data() as Map<String, dynamic>;
                final ts = data['scheduledAt'] as Timestamp?;
                final parts = List<String>.from(data['participants'] ?? []);
                if (ts == null) continue;
                final names = <String>[];
                for (final uid in parts) {
                  final u = await _getUser(uid);
                  if (u != null) {
                    names.add("${u['displayName']} (${u['email']})");
                  } else {
                    names.add(uid);
                  }
                }
                final title = names.join(" ↔ ");
                final d = ts.toDate();
                final day = DateTime(d.year, d.month, d.day);
                map.putIfAbsent(day, () => []);
                map[day]!.add(title);
              }
              return map;
            }(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final events = snap.data!;
              return TableCalendar(
                focusedDay: DateTime.now(),
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                eventLoader: (day) => events[day] ?? [],
                onDaySelected: (d, f) {
                  final titles = events[d] ?? [];
                  if (titles.isNotEmpty) {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => ListView(
                        children: titles.map((t) => ListTile(
                          leading: const Icon(Icons.video_call),
                          title: Text(t),
                        )).toList(),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// --- Page 5: Login ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (optional)')),
              TextField(controller: passController, obscureText: true, decoration: const InputDecoration(labelText: 'Password (optional)')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  String email = emailController.text.trim();
                  String pass = passController.text.trim();
                  if (email.isEmpty) email = "${_randomString(6)}@example.com";
                  if (pass.isEmpty) pass = _randomString(10);
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'user-not-found') {
                      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
                      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                        'displayName': email.split('@').first,
                        'email': email,
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: ${e.message}')));
                    }
                  }
                },
                child: const Text('Login / Register (or random if blank)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
