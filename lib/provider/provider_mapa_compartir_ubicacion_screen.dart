import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../global/variables_globales.dart';
import '../google_maps_api_key.dart';
import '../modelos/ruta_actual.dart';
import '../modelos/ruta_api_google.dart';

import 'package:http/http.dart' as http;

class ProviderMapaCompartirUbicacionScreen extends ChangeNotifier {
  static late GoogleMapController googleMapController;

  Set<Marker> _listaMarkers = {};
  Set<Polyline> _polylineRuta = {};

  set listaMarkers(Set<Marker> lista) {
    _listaMarkers = lista;
    notifyListeners();
  }

  set polylineRuta(Set<Polyline> polyline) {
    _polylineRuta = polyline;
    notifyListeners();
  }

  Set<Polyline> get polylineRuta => _polylineRuta;
  Set<Marker> get listaMarkers => _listaMarkers;

  static Future<void> permisoUbicacion() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.

      permission = await Geolocator.requestPermission();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    posicionActual = await Geolocator.getCurrentPosition();

    moverCamara();
  }

  static void moverCamara() {
    googleMapController.moveCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            bearing: 192.8334901395799,
            target: LatLng(posicionActual.latitude, posicionActual.longitude),
            tilt: 59.440717697143555,
            zoom: 15)));
  }

  static void consultarRutaCompartida(String url, BuildContext context) async {
    if (!url.startsWith("https://mi-ruta-taxi-pasajero.com/")) {
      return;
    }

    final idSolicitud = url
        .split("https://mi-ruta-taxi-pasajero.com/")[1]
        .split("/ubicacion-actual")
        .first;

    bool calcularRutaUnaVez = true;

    streamSuscriptionEscucharRutaCompartidaMapa = FirebaseFirestore.instance
        .collection("solicitudes")
        .doc(idSolicitud)
        .snapshots()
        .listen((snapshot) {
      final objRuta = RutaActual.fromJson(snapshot.data()!);

      if (objRuta.status != "enRuta") {
        Provider.of<ProviderMapaCompartirUbicacionScreen>(context,
                listen: false)
            .listaMarkers = {};
        Provider.of<ProviderMapaCompartirUbicacionScreen>(context,
                listen: false)
            .polylineRuta = {};
        streamSuscriptionEscucharRutaCompartidaMapa.cancel();
        calcularRutaUnaVez = true;
        return;
      } else {
        if (calcularRutaUnaVez) {
          calcularRuta(context, objRuta);
          calcularRutaUnaVez = false;
        } else {
          LatLng latLngInicio = LatLng(objRuta.coordenadasInicio.latitud,
              objRuta.coordenadasInicio.longitud);
          LatLng latLngDestino = LatLng(objRuta.coordenadasDestino.latitud,
              objRuta.coordenadasDestino.longitud);
          LatLng latLngPosicionCliente = LatLng(
              objRuta.coordenadasPosicionCliente.latitud,
              objRuta.coordenadasPosicionCliente.longitud);

          final nombreLugarInicio = objRuta.lugarInicio;
          final nombreLugarDestino = objRuta.lugarDestino;

          Set<Marker> markers = {};
          markers.add(Marker(
            markerId: const MarkerId("Marker-posicion-actual"),
            position: latLngInicio,
            infoWindow:
                InfoWindow(title: "Inicio de ruta", snippet: nombreLugarInicio),
          ));

          markers.add(Marker(
            markerId: const MarkerId("Marker-posicion-destino"),
            position: latLngDestino,
            infoWindow: InfoWindow(
                title: "Destino del pasajero", snippet: nombreLugarDestino),
          ));

          markers.add(Marker(
            markerId: const MarkerId("Marker-posicion-pasajero"),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            position: latLngPosicionCliente,
            infoWindow: const InfoWindow(title: "Posicion del pasajero"),
          ));

          Provider.of<ProviderMapaCompartirUbicacionScreen>(context,
                  listen: false)
              .listaMarkers = markers;
        }
      }
    });
  }

  static void calcularRuta(BuildContext context, RutaActual rutaActual) async {
    LatLng latLngInicio = LatLng(rutaActual.coordenadasInicio.latitud,
        rutaActual.coordenadasInicio.longitud);
    LatLng latLngDestino = LatLng(rutaActual.coordenadasDestino.latitud,
        rutaActual.coordenadasDestino.longitud);
    LatLng latLngPosicionCliente = LatLng(
        rutaActual.coordenadasPosicionCliente.latitud,
        rutaActual.coordenadasPosicionCliente.longitud);

    rutaApiGoogle = await _obtenerRuta(latLngInicio, latLngDestino);

    final nombreLugarInicio = rutaActual.lugarInicio;
    final nombreLugarDestino = rutaActual.lugarDestino;

    Set<Marker> markers = {};
    markers.add(Marker(
      markerId: const MarkerId("Marker-posicion-actual"),
      position: latLngInicio,
      infoWindow: InfoWindow(
          title: "Posicion del pasajero", snippet: nombreLugarInicio),
    ));

    markers.add(Marker(
      markerId: const MarkerId("Marker-posicion-destino"),
      position: latLngDestino,
      infoWindow: InfoWindow(
          title: "Destino del pasajero", snippet: nombreLugarDestino),
    ));

    markers.add(Marker(
      markerId: const MarkerId("Marker-posicion-pasajero"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      position: latLngPosicionCliente,
      infoWindow: const InfoWindow(title: "Posicion del pasajero"),
    ));

    List<LatLng> pLineCoordinates = [];
    Set<Polyline> polylineSet = {};
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResult =
        polylinePoints.decodePolyline(rutaApiGoogle.rutaCodificada);

    if (decodePolylinePointsResult.isNotEmpty) {
      for (var pointLatLng in decodePolylinePointsResult) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    Polyline polyline = Polyline(
        polylineId: const PolylineId("ruta-codificada"),
        color: Colors.black,
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 4);

    polylineSet.add(polyline);

    Provider.of<ProviderMapaCompartirUbicacionScreen>(context, listen: false)
        .listaMarkers = markers;
    Provider.of<ProviderMapaCompartirUbicacionScreen>(context, listen: false)
        .polylineRuta = polylineSet;
  }

  static Future<RutaApiGoogle> _obtenerRuta(
      LatLng latLngInicio, LatLng latLngDestino) async {
    final uri = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=${latLngInicio.latitude},${latLngInicio.longitude}&destination=${latLngDestino.latitude},${latLngDestino.longitude}&key=$googleMapsApiKey");

    final response = await http.get(uri);

    final decodedData = json.decode(response.body);

    return RutaApiGoogle.fromJson(decodedData);
  }
}
