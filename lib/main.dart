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
      title: 'Aplicación Firebase',
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
  late Future<List<Map<String, dynamic>>> listaUsuarios;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  void _cargarUsuarios() {
    setState(() {
      listaUsuarios = _obtenerUsuarios();
    });
  }

  Future<List<Map<String, dynamic>>> _obtenerUsuarios() async {
    try {
      QuerySnapshot query = await db.collection("usuarios").get();
      return query.docs.map((doc) {
        return {
          'uid': doc.id,
          'dni': doc['dni'] ?? 'Sin DNI',
          'nombre': doc['nombre'] ?? 'Sin Nombre',
        };
      }).toList();
    } catch (e) {
      print("Error al cargar usuarios: $e");
      return [];
    }
  }

  Future<void> _agregarUsuario() async {
    if (_controllerDNI.text.isEmpty || _controllerNombre.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("DNI y Nombre son requeridos")),
      );
      return;
    }

    try {
      await db.collection("usuarios").add({
        'dni': _controllerDNI.text,
        'nombre': _controllerNombre.text,
      });
      _controllerDNI.clear();
      _controllerNombre.clear();
      _cargarUsuarios();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al agregar: $e")),
      );
    }
  }

  Future<void> _actualizarUsuario(String uid, String nuevoNombre) async {
    try {
      await db.collection("usuarios").doc(uid).update({
        'nombre': nuevoNombre,
      });
      _cargarUsuarios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar: $e")),
      );
    }
  }

  Future<void> _eliminarUsuario(String uid) async {
    try {
      await db.collection("usuarios").doc(uid).delete();
      _cargarUsuarios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar: $e")),
      );
    }
  }

  void _mostrarDialogoAgregar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Agregar Usuario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controllerDNI,
              decoration: const InputDecoration(labelText: "DNI"),
            ),
            TextField(
              controller: _controllerNombre,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: _agregarUsuario,
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditar(String uid, String nombreActual) {
    final controller = TextEditingController(text: nombreActual);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Usuario"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nuevo nombre"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              _actualizarUsuario(uid, controller.text);
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: listaUsuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar usuarios"));
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay usuarios"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final usuario = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(usuario['nombre']),
                  subtitle: Text("DNI: ${usuario['dni']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _mostrarDialogoEditar(
                          usuario['uid'], usuario['nombre']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarUsuario(usuario['uid']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAgregar,
        child: const Icon(Icons.add),
      ),
    );
  }
}