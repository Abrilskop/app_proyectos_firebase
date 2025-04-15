import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Aplicación Firebase'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controllerDNI = TextEditingController();
  final TextEditingController _controllerNombre = TextEditingController();
  late Future<List> listaUsuarios;

  @override
  void initState() {
    super.initState();
    listaUsuarios = obtenerUsuario();
  }

  Future<List> obtenerUsuario() async {
    List usuarios = [];
    try {
      QuerySnapshot queryUsuarios = await db.collection("usuarios").get();
      for (var documento in queryUsuarios.docs) {
        Map<String, dynamic> dataConfig = documento.data() as Map<String, dynamic>;
        usuarios.add({
          'dni': dataConfig['dni'] ?? 'Sin DNI',
          'nombre': dataConfig['nombre'] ?? 'Sin Nombre',
          'uid': documento.id,
        });
      }
    } catch (e) {
      print("Error al obtener usuarios: $e");
    }
    return usuarios;
  }

  Future<void> agregarUsuario(String dni, String nombre) async {
    await db.collection("usuarios").add({
      'dni': dni,
      'nombre': nombre,
    });
  }

  Future<void> actualizarUsuario(String uid, String dni, String nombre) async {
    await db.collection("usuarios").doc(uid).update({
      'dni': dni,
      'nombre': nombre,
    });
  }

  Future<void> eliminarUsuario(String uid) async {
    try {
      await db.collection("usuarios").doc(uid).delete();
    } catch (e) {
      print('Error eliminando usuario: $e');
    }
  }

  void mostrarLista() {
    setState(() {
      listaUsuarios = obtenerUsuario();
    });
  }

  void dialogAgregarUsuario() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Agregar Usuario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controllerDNI,
              decoration: const InputDecoration(hintText: "DNI"),
            ),
            TextField(
              controller: _controllerNombre,
              decoration: const InputDecoration(hintText: "Nombre"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await agregarUsuario(
                _controllerDNI.text,
                _controllerNombre.text,
              );
              _controllerDNI.clear();
              _controllerNombre.clear();
              mostrarLista();
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String uid, String dni, String currentNombre) {
    TextEditingController nombreController = TextEditingController(text: currentNombre);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modificar Usuario"),
        content: TextField(
          controller: nombreController,
          decoration: const InputDecoration(hintText: "Nuevo nombre"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await actualizarUsuario(uid, dni, nombreController.text);
              mostrarLista();
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: FutureBuilder<List>(
          future: listaUsuarios,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text("Error al cargar usuarios"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No se encontraron usuarios."));
            }

            return ListView.separated(
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final usuario = snapshot.data![index];
                return ListTile(
                  title: Text(usuario['nombre']),
                  subtitle: Text("DNI: ${usuario['dni']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => eliminarUsuario(usuario['uid']).then((_) => mostrarLista()),
                  ),
                  onTap: () => _showEditDialog(usuario['uid'], usuario['dni'], usuario['nombre']),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: dialogAgregarUsuario,
            child: const Icon(Icons.add),
            ),
        );
    }
}