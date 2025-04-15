import 'package:cloud_firestore/cloud_firestore.dart';

class InstanciaDB {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ejemplo: añadir un documento a una colección
  Future<void> agregarDocumento(String coleccion, Map<String, dynamic> datos) async {
    await _db.collection(coleccion).add(datos);
  }

  // Ejemplo: obtener todos los documentos de una colección
  Stream<QuerySnapshot> obtenerDocumentos(String coleccion) {
    return _db.collection(coleccion).snapshots();
  }

  // Ejemplo: actualizar un documento
  Future<void> actualizarDocumento(String coleccion, String id, Map<String, dynamic> nuevosDatos) async {
    await _db.collection(coleccion).doc(id).update(nuevosDatos);
  }

  // Ejemplo: eliminar un documento
  Future<void> eliminarDocumento(String coleccion, String id) async {
    await _db.collection(coleccion).doc(id).delete();
  }
}