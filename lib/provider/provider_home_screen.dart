import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pide_taxi_pasajero_v2/global/variables_globales.dart';
import 'package:pide_taxi_pasajero_v2/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../flirebase_messaging_key.dart';
import '../modelos/ruta_actual.dart';
import '../modelos/taxista_disponible.dart';
import '../widgets/dialogo_progreso.dart';
import 'provider_google_apis.dart';

class ProviderHomeScreen extends ChangeNotifier {
  static late GoogleMapController googleMapController;

  static late BuildContext contextoHomeScreen;

  Set<Marker> _listaMarkers = {};
  Set<Polyline> _polylineRuta = {};
  bool _solicitandoRuta = false;
  bool _solicitudRutaAceptada = false;

  set solicitudRutaAceptada(bool valor) {
    _solicitudRutaAceptada = valor;
    notifyListeners();
  }

  bool get solicitudRutaAceptada => _solicitudRutaAceptada;

  set solicitandoRuta(bool valor) {
    _solicitandoRuta = valor;
    notifyListeners();
  }

  bool get solicitandoRuta => _solicitandoRuta;

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

  static void cerrarSesion(BuildContext context) async {
    streamSuscriptionEscucharNotificacionesAppAbierta.cancel();
    streamSuscriptionEscucharNotificacionesAppSinAbrir.cancel();
    streamEscucharRutaActual.cancel();
    Navigator.pushNamedAndRemoveUntil(
        context, LoginScreen.idScreen, (route) => false);
    await FirebaseAuth.instance.signOut();
  }

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

  static void consultarUsuario() async {
    usuarioActual = FirebaseAuth.instance.currentUser!;
    final tokenActual = await FirebaseMessaging.instance.getToken();
    FirebaseFirestore.instance
        .collection("usuarios")
        .doc(usuarioActual.uid)
        .update({"token": tokenActual});
  }

  static void calcularRuta() async {
    showDialog(
        barrierDismissible: false,
        context: contextoHomeScreen,
        builder: (BuildContext context) => const DialogoProgreso(
            titulo: "Calculando ruta . . .",
            color: Colors.amber,
            child: CircularProgressIndicator()));

    rutaApiGoogle = await ProviderGoogleApis.obtenerRuta();

    final latlngInicio = rutaActual.idTaxista == "no-data"
        ? LatLng(
            detallesDireccionActual.latitud, detallesDireccionActual.longitud)
        : LatLng(rutaActual.coordenadasInicio.latitud,
            rutaActual.coordenadasInicio.longitud);
    final latlngDestino = rutaActual.idTaxista == "no-data"
        ? LatLng(
            detallesDireccionDestino.latitud, detallesDireccionDestino.longitud)
        : LatLng(rutaActual.coordenadasDestino.latitud,
            rutaActual.coordenadasDestino.longitud);
    final nombreLugarInicio = rutaActual.idTaxista == "no-data"
        ? detallesDireccionActual.nombreLugar
        : rutaActual.lugarInicio;
    final nombreLugarDestino = rutaActual.idTaxista == "no-data"
        ? detallesDireccionDestino.nombreLugar
        : rutaActual.lugarDestino;

    Set<Marker> markers = {};
    markers.add(Marker(
      markerId: const MarkerId("Marker-posicion-actual"),
      position: latlngInicio,
      infoWindow: InfoWindow(
          title: "Posicion del pasajero", snippet: nombreLugarInicio),
    ));

    markers.add(Marker(
      markerId: const MarkerId("Marker-posicion-destino"),
      position: latlngDestino,
      infoWindow: InfoWindow(
          title: "Destino del pasajero", snippet: nombreLugarDestino),
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

    Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
        .listaMarkers = markers;
    Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
        .polylineRuta = polylineSet;
    rutaActual.idTaxista == "no-data"
        ? Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .solicitandoRuta = true
        : Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .solicitandoRuta = false;

    Navigator.pop(contextoHomeScreen); // para cerrar el dialogo de carga
  }

  static void cancelarSolicitudRuta() async {
    rutaActual = RutaActual();
    Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
        .solicitandoRuta = false;
    Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
        .listaMarkers = {};
    Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
        .polylineRuta = {};
  }

  static Future<void> cancelarBusquedaTaxi() async {
    timerSolicitandoTaxi.cancel();
    await FirebaseFirestore.instance
        .collection('solicitudes')
        .doc(rutaActual.idSolicitud)
        .delete();
    rutaActual = RutaActual();
    return;
  }

  static Future<void> cancelarRutaActual() async {
    await FirebaseFirestore.instance
        .collection('solicitudes')
        .doc(rutaActual.idSolicitud)
        .delete();
    rutaActual = RutaActual();
    return;
  }

  static Future<void> terminarRuta() async {
    streamSubscriptionEscucharPosicionActual == null
        ? null
        : streamSubscriptionEscucharPosicionActual!.cancel();

    FirebaseFirestore.instance
        .collection("taxistas")
        .doc(rutaActual.idTaxista)
        .get()
        .then((value) {
      // GANANCIAS
      double ganancias = value.data()!["ganancias"];
      ganancias += rutaActual.costoRuta;

      FirebaseFirestore.instance
          .collection("taxistas")
          .doc(rutaActual.idTaxista)
          .get()
          .then((value) {
        // RAITING
        double raiting = value.data()!["raiting"];
        raiting = (raiting + raitingCliente) / 2;

        // ACTUALIZAR DATOS
        FirebaseFirestore.instance
            .collection("taxistas")
            .doc(rutaActual.idTaxista)
            .update({"ganancias": ganancias, "raiting": raiting});

        //TERMINAR RUTA
        FirebaseFirestore.instance
            .collection("solicitudes")
            .doc(rutaActual.idSolicitud)
            .update({"status": "terminado"}).then((value) {
          rutaActual = RutaActual();
        });
        return;
      });
    });
  }

  static Future<void> cambiarStatusRutaActual(
      String idSolicitud, String status) async {}

  static Future<void> escucharRutaActual() async {
    streamEscucharRutaActual = FirebaseFirestore.instance
        .collection("solicitudes")
        .where("id_cliente", isEqualTo: usuarioActual.uid.toString())
        .where("status", isNotEqualTo: "terminado")
        .orderBy("status")
        .snapshots()
        .listen((event) {
      Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
          .solicitudRutaAceptada = false;

      if (event.docs.isEmpty) {
        Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .solicitudRutaAceptada = false;
        Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .polylineRuta = {};
        Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .listaMarkers = {};
        return;
      }

      RutaActual objRuta = RutaActual();
      final rutasActuales = event.docs.map((e) {
        final objRutaActual = RutaActual.fromJson(e.data());

        objRutaActual.idSolicitud = e.id;

        return objRutaActual;
      }).toList();

      for (var ruta in rutasActuales) {
        if (ruta.status == "aceptado" ||
            ruta.status == "enRuta" ||
            ruta.status == "pagando") {
          objRuta = ruta;
          break;
        }
      }

      if (objRuta.status == "aceptado" ||
          objRuta.status == "enRuta" ||
          objRuta.status == "pagando") {
        rutaActual = objRuta;
        Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .solicitudRutaAceptada = true;
        Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .solicitandoRuta = false;
        calcularRuta();
      } else {
        Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .solicitudRutaAceptada = false;
        Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .polylineRuta = {};
        Provider.of<ProviderHomeScreen>(contextoHomeScreen, listen: false)
            .listaMarkers = {};
      }
    });
  }

  static void solicitarBusquedaTaxi() async {
    showDialog(
        barrierDismissible: false,
        context: contextoHomeScreen,
        builder: (context) => DialogoProgreso(
              titulo: "Solicitando taxi . . . ",
              color: Colors.amber,
              child: Column(children: [
                const CircularProgressIndicator(),
                ElevatedButton(
                    child: const Text("Cancelar solicitud"),
                    onPressed: () async {
                      await ProviderHomeScreen.cancelarBusquedaTaxi();
                      Navigator.pop(context);
                    })
              ]),
            ));

    rutaActual.idSolicitud =
        FirebaseFirestore.instance.collection('solicitudes').doc().id;

    final documentoUsuario = await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(usuarioActual.uid)
        .get();

    final mapaDatosUsuario = documentoUsuario.data()!;

    final Map<String, dynamic> mapaSolicitud = {
      'costo_ruta': _calcularCostoRuta(),
      'duracion_ruta': rutaApiGoogle.textoDuracion,
      'distancia_ruta': rutaApiGoogle.textoDistancia,
      'fecha': DateTime.now().toString(),
      'cantidad_pasajeros': cantidadPasajeros,
      'id_cliente': usuarioActual.uid,
      'nombre_cliente': mapaDatosUsuario['nombre'],
      'telefono_cliente': mapaDatosUsuario['telefono'],
      'token_cliente': mapaDatosUsuario['token'],
      'status': 'solicitando',
      'id_taxista': 'no-data',
      'telefono_taxista': 'no-data',
      'token_taxista': 'no-data',
      'nombre_taxista': 'no-data',
      'datos_auto_taxista': {
        'modelo': 'no-data',
        'placa': 'no-data',
        'color': 'no-data',
      },
      'lugar_inicio': detallesDireccionActual.nombreLugar,
      'lugar_destino': detallesDireccionDestino.nombreLugar,
      'tipo_solicitud': 'con-destino',
      'coordenadas_inicio': {
        'latitud': detallesDireccionActual.latitud,
        'longitud': detallesDireccionActual.longitud,
      },
      'coordenadas_destino': {
        'latitud': detallesDireccionDestino.latitud,
        'longitud': detallesDireccionDestino.longitud,
      },
      'coordenadas_posicion_taxista': {
        'latitud': 0.0,
        'longitud': 0.0,
      },
      'coordenadas_posicion_cliente': {
        'latitud': posicionActual.latitude,
        'longitud': posicionActual.longitude,
      },
    };

    await FirebaseFirestore.instance
        .collection("solicitudes")
        .doc(rutaActual.idSolicitud)
        .set(mapaSolicitud);
    //aqui va el codigo para buscar taxi
    esperandoRespuestaTaxistaEncontrado();
  }

  static void esperandoRespuestaTaxistaEncontrado() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("taxistas-disponibles")
        .get();

    final listaTaxistasDisponibles =
        querySnapshot.docs.map((DocumentSnapshot e) {
      return TaxistaDisponible.fromJson(e.data() as Map<String, dynamic>, e.id);
    }).toList();

    if (listaTaxistasDisponibles.isEmpty) {
      Navigator.pop(
          contextoHomeScreen); // para cerrar el dialogo de buscando taxi
      showDialog(
          context: contextoHomeScreen,
          barrierDismissible: true,
          builder: (builder) => const DialogoProgreso(
                titulo: "No hay taxistas disponibles",
                color: Colors.redAccent,
              ));
      cancelarBusquedaTaxi();
    } else {
      _enviarPosicionActualTiempoReal();

      int tiempoRespuestaSolicitud = 10;

//  AQUI SE ENVIAN LAS NOTIFICACIONES A LOS TAXISTAS
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// para verificar que el indice no sea mayor al tamano de la lista de taxistas
      indiceListaTaxistasDisponibles =
          indiceListaTaxistasDisponibles >= listaTaxistasDisponibles.length
              ? 0
              : indiceListaTaxistasDisponibles;

//obtenemos el token del taxista
      final documentTaxista = await FirebaseFirestore.instance
          .collection("taxistas")
          .doc(listaTaxistasDisponibles[indiceListaTaxistasDisponibles].id)
          .get();

//mandamos la notificacion al taxista a travez de su token obtenido
      await _enviarNotificacion(documentTaxista.data()!["token"]);

      indiceListaTaxistasDisponibles += 1;

      indiceListaTaxistasDisponibles =
          indiceListaTaxistasDisponibles >= listaTaxistasDisponibles.length
              ? 0
              : indiceListaTaxistasDisponibles;

//obtenemos el token del taxista
      final documentTaxista2 = await FirebaseFirestore.instance
          .collection("taxistas")
          .doc(listaTaxistasDisponibles[indiceListaTaxistasDisponibles].id)
          .get();

//mandamos la notificacion al taxista a travez de su token obtenido
      await _enviarNotificacion(documentTaxista2.data()!["token"]);
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

      timerSolicitandoTaxi =
          Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
        // final documentSnapshotSolicitudRuta = await FirebaseFirestore.instance.collection("solicitudes").doc(idSolicitudRuta).get();

        // final rutaActual = RutaActual.fromJson(documentSnapshotSolicitudRuta.data()!);

        if (rutaActual.idTaxista != "no-data") {
          timerSolicitandoTaxi.cancel();
          // =============== PARA CERRAR EL DIALOG DE SOLICITANDO TAXI =============
          Navigator.pop(contextoHomeScreen);
          // =============== PARA CERRAR EL DIALOG DE SOLICITANDO TAXI =============
        }
        if (tiempoRespuestaSolicitud == 0) {
          // print("se cancela escuchar ruta actual y escuchar posicion actual");
          // streamSuscriptionEscucharRutaActual.cancel();
          // streamSubscriptionEscucharPosicionActual.cancel();

          await cancelarBusquedaTaxi();
          // =============== PARA CERRAR EL DIALOG DE SOLICITANDO TAXI =============
          Navigator.pop(contextoHomeScreen);
          // =============== PARA CERRAR EL DIALOG DE SOLICITANDO TAXI =============
          solicitarBusquedaTaxi();
        }
        tiempoRespuestaSolicitud--;
      });
    }
  }

  static void _enviarPosicionActualTiempoReal() {
    streamSubscriptionEscucharPosicionActual = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(distanceFilter: 10))
        .listen((position) async {
      if (rutaActual.idSolicitud != "no-data") {
        await FirebaseFirestore.instance
            .collection("solicitudes")
            .doc(rutaActual.idSolicitud)
            .update({
          "coordenadas_posicion_cliente": {
            "latitud": position.latitude,
            "longitud": position.longitude
          }
        });
      }
    });
  }

  static Future<void> compartirRuta() async => await Share.share(
      "Ingresa a la app y mira mi ubicacion!!\n\nhttps://mi-ruta-taxi-pasajero.com/${rutaActual.idSolicitud}/ubicacion-actual",
      subject: "Ingresa a la app y revisa mi ubicacion!");

  static void escucharNotificacionesAppAbierta() {
    streamSuscriptionEscucharNotificacionesAppAbierta =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPluginMessaging.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: "launch_background",
            ),
          ),
        );
      }
    });
  }

  static void escucharNotificacionesAppSinAbrir() {
    streamSuscriptionEscucharNotificacionesAppSinAbrir =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPluginMessaging.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: "launch_background",
            ),
          ),
        );
      }
    });
  }

  static Future<http.Response> _enviarNotificacion(String token) async {
    Uri uri = Uri.parse("https://fcm.googleapis.com/fcm/send");

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "key=$firebaseMessagingKey"
    };

    Map<String, String> dataMap = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "id_solicitud": rutaActual.idSolicitud,
    };

    Map<String, dynamic> notificationMap = {
      "title": "Hay una nueva solicitud de taxi!",
      "body": "Destino - ${detallesDireccionDestino.nombreLugar}"
    };

    Map<String, dynamic> body = {
      "to": token,
      "notification": notificationMap,
      "data": dataMap
    };

    return await http.post(uri, headers: headers, body: json.encode(body));
  }

  static double _calcularCostoRuta() {
    final totalMililitros = mililitrosXkilometro *
        (rutaApiGoogle.valorDistancia / 1000); // VALOR DISTANCIA EN METROS
    final costoViajeGasolinaXLitro = costoLitroGasolina * totalMililitros;
    return double.parse((costoViajeGasolinaXLitro + 55).toStringAsFixed(2));
  }
}
