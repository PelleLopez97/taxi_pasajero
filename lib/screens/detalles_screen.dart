import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pide_taxi_pasajero_v2/global/variables_globales.dart';

import '../modelos/ruta_actual.dart';

class DetallesScreen extends StatelessWidget {
  const DetallesScreen({super.key});

  static const idScreen = "detalles";

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(child: _RutasTerminadas(size: size)),
    );
  }
}

class _RutasTerminadas extends StatelessWidget {
  final Size size;
  const _RutasTerminadas({required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          left: size.width * 0.02,
          right: size.width * 0.02,
          top: size.height * 0.005),
      width: size.width,
      height: size.height * 0.94,
      decoration: const BoxDecoration(
          // color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: StreamBuilder(
        builder: (context, snapshot) {
          // print("lengh data => ${snapshot.data!.docs.length}");

          if (!snapshot.hasData) {
            return const Text("no data");
          }

          final registrosViajesTerminados = snapshot.data!.docs
              .map((DocumentSnapshot e) =>
                  RutaActual.fromJson(e.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            itemCount: registrosViajesTerminados.length,
            itemBuilder: (context, index) {
              return _ItemDetallesRutaActual(
                  rutaActual: registrosViajesTerminados[index], size: size);
            },
          );
        },
        stream: FirebaseFirestore.instance
            .collection("solicitudes")
            .where("id_cliente", isEqualTo: usuarioActual.uid.toString())
            .where("status", isEqualTo: "terminado")
            .snapshots(),
      ),
    );
  }
}

class _ItemDetallesRutaActual extends StatelessWidget {
  final Size size;

  final RutaActual rutaActual;

  const _ItemDetallesRutaActual({
    Key? key,
    required this.rutaActual,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(size.width * 0.02),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black, blurRadius: 0, spreadRadius: 2)
          ],
          borderRadius: BorderRadius.all(Radius.circular(5))),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
            margin: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  "Distancia ${rutaActual.distanciaRuta}",
                ),
                Text(
                  "Tiempo estimado ${rutaActual.duracionRuta}",
                ),
                Text(
                  "Costo de la ruta\$${rutaActual.costoRuta}",
                ),
                _ListTileCustom(
                    size: size,
                    title: rutaActual.lugarInicio,
                    subtitle: "Mi ubicación"),
                _ListTileCustom(
                    size: size,
                    title: rutaActual.lugarDestino,
                    subtitle: "Mi destino"),
                _ListTileCustom(
                  size: size,
                  title: rutaActual.cantidadPasajeros.toString(),
                  subtitle: "Cantidad de pasajeros",
                ),
                _ListTileCustom(
                  size: size,
                  title: rutaActual.telefonoCliente,
                  subtitle: "Telefono del cliente",
                ),
                _ListTileCustom(
                  size: size,
                  title: rutaActual.nombreCliente,
                  subtitle: "Nombre del cliente",
                ),
              ],
            )),
      ]),
    );
  }
}

class _ListTileCustom extends StatelessWidget {
  final Size size;
  const _ListTileCustom(
      {Key? key,
      required this.title,
      required this.subtitle,
      required this.size})
      : super(key: key);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width * 0.90,
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 1, spreadRadius: 0.5)
          ],
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }
}
