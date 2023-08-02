import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthModel>(
      builder: (context, auth, child) {
        if (auth.isAuthenticated) {
          return MaterialApp(
            home: HomePage(),
          );
        } else {
          return MaterialApp(
            home: LoginPage(),
          );
        }
      },
    );
  }
}

class AuthModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  AuthModel() {
    _auth.authStateChanges().listen((User? user) {
      print('recieved Changes: user = $user');
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;

  bool get isAuthenticated => user != null;

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.message!.contains('network-error')) {
          print('Network error detected');
          // Handle network error
        } else if (e.message!.contains('no user record corresponding')) {
          print('not register yet');
          // Handle network error
        } else {
          print('Firebase Login Error : ${e.message}');
          // Handle other errors
        }
      } else {
        print('Basic Login Error : $e');
      }
    }
  }

  Future<void> register(BuildContext context, String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);
      UserCredential result = await _auth.signInWithCredential(credential);

      print('userCredential : $userCredential');
      print('credential : $credential');
      print('result : $result');
      print('Current user after registration: ${_auth.currentUser}');
      notifyListeners();
      Navigator.pop(context);
    } catch (e) {
      print('register Error: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () {
                Provider.of<AuthModel>(context, listen: false).login(
                  emailController.text,
                  passwordController.text,
                );
              },
            ),
            ElevatedButton(
              child: Text('Don\'t have an account? Register'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              child: Text('Register'),
              onPressed: () {
                Provider.of<AuthModel>(context, listen: false).register(
                  context,
                  emailController.text,
                  passwordController.text,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthModel>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: Center(child: Text('Welcome home!')),
    );
  }
}
