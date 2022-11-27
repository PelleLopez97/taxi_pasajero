import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../modelos/detalles_direccion_google_api.dart';
import '../modelos/ruta_actual.dart';
import '../modelos/ruta_api_google.dart';

// *********************************************************** //
TextEditingController controllerNombreUsuario = TextEditingController();
TextEditingController controllerTelefonoUsuario = TextEditingController();
TextEditingController controllerCorreoUsuario = TextEditingController();
TextEditingController controllerContrasenaUsuario = TextEditingController();
TextEditingController controllerModeloAuto = TextEditingController();
TextEditingController controllerPlacaAuto = TextEditingController();
TextEditingController controllerColorAuto = TextEditingController();
// *********************************************************** //
late Timer timerSolicitandoTaxi;
// *********************************************************** //
late RutaApiGoogle rutaApiGoogle;
// *********************************************************** //
int cantidadPasajeros = 1;
// *********************************************************** //
int indiceListaTaxistasDisponibles = 0;
// *********************************************************** //
const mililitrosXkilometro = 0.083;
const costoServicioTaxi = 50;
const costoLitroGasolina = 25;
// *********************************************************** //
late StreamSubscription<RemoteMessage>
    streamSuscriptionEscucharNotificacionesAppAbierta;
late StreamSubscription<RemoteMessage>
    streamSuscriptionEscucharNotificacionesAppSinAbrir;
late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
    streamSuscriptionEscucharRutaCompartidaMapa;
late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
    streamEscucharRutaActual;
late StreamSubscription<Position>? streamSubscriptionEscucharPosicionActual;
// *********************************************************** //
late DetallesDireccionGoogleApi detallesDireccionDestino;
late DetallesDireccionGoogleApi detallesDireccionActual;
// *********************************************************** //
RutaActual rutaActual = RutaActual();
// *********************************************************** //
late User usuarioActual;
// *********************************************************** //
bool calcularRutaUnaVez = true;
// *********************************************************** //
late Position posicionActual;
// *********************************************************** //
late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPluginMessaging;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPluginRealtime;
// *********************************************************** //
const camaraInicial = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(17.553113673601146, -99.5135981438487),
    tilt: 59.440717697143555,
    zoom: 15);
// *********************************************************** //
double raitingCliente = 0.0;
// *********************************************************** //
// *********************************************************** //