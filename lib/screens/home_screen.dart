import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pide_taxi_pasajero_v2/screens/detalles_screen.dart';
import 'package:provider/provider.dart';

import '../global/variables_globales.dart';
import '../provider/provider_animacion_pantalla.dart';
import '../provider/provider_home_screen.dart';
import '../widgets/dialogo_progreso.dart';
import 'busqueda_screen.dart';
import 'mapa_ubicacion_compartida_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  static const idScreen = 'home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ProviderHomeScreen.contextoHomeScreen = context;
    ProviderHomeScreen.escucharNotificacionesAppAbierta();
    ProviderHomeScreen.escucharNotificacionesAppSinAbrir();
    ProviderHomeScreen.consultarUsuario();
    ProviderHomeScreen.permisoUbicacion();
    ProviderHomeScreen.escucharRutaActual();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                  tooltip: "Ver ruta en tiempo real",
                  onPressed: () => Navigator.pushNamed(
                      context, MapaUbicacionCompartidaScreen.idScreen),
                  icon: const Icon(Icons.location_on_outlined)),
              IconButton(
                  tooltip: "Historial de viajes",
                  onPressed: () =>
                      Navigator.pushNamed(context, DetallesScreen.idScreen),
                  icon: const Icon(Icons.history_rounded)),
              IconButton(
                  tooltip: "Cerrar sesion",
                  onPressed: () => ProviderHomeScreen.cerrarSesion(context),
                  icon: const Icon(Icons.login_outlined)),
            ],
          ),
        ),
        floatingActionButton:
            Provider.of<ProviderHomeScreen>(context).solicitudRutaAceptada
                ? const SizedBox.shrink()
                : FloatingActionButton(
                    onPressed:
                        Provider.of<ProviderHomeScreen>(context).solicitandoRuta
                            ? () async {
                                ProviderHomeScreen.cancelarSolicitudRuta();
                              }
                            : () async {
                                final respuesta = await showSearch(
                                    context: context,
                                    delegate: BusquedaScreen());

                                if (respuesta == "busqueda-completa") {
                                  ProviderHomeScreen.calcularRuta();
                                }
                              },
                    child: Icon(
                        Provider.of<ProviderHomeScreen>(context, listen: false)
                                .solicitandoRuta
                            ? Icons.cancel
                            : Icons.local_taxi_outlined)),
        body: SafeArea(
          child: Stack(
            children: [
              _MapaUsuario(size: size),
              Provider.of<ProviderHomeScreen>(context, listen: false)
                      .solicitandoRuta
                  ? _DetallesRutaSolicitada(size: size)
                  : Provider.of<ProviderHomeScreen>(context, listen: false)
                          .solicitudRutaAceptada
                      ? _RutaActual(size: size)
                      : const SizedBox.shrink(),
              // Provider.of<ProviderHomeScreen>(context).solicitudRutaAceptada ? _RutaActual(size: size) : const SizedBox.shrink()
            ],
          ),
        ));
  }
}

class _MapaUsuario extends StatefulWidget {
  final Size size;

  const _MapaUsuario({required this.size});

  @override
  State<_MapaUsuario> createState() => _MapaUsuarioState();
}

class _MapaUsuarioState extends State<_MapaUsuario> {
  final initialCameraPosition = const CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(17.553113673601146, -99.5135981438487),
      tilt: 59.440717697143555,
      zoom: 15);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: GoogleMap(
          mapType: MapType.normal,
          markers: Provider.of<ProviderHomeScreen>(context, listen: false)
              .listaMarkers,
          polylines: Provider.of<ProviderHomeScreen>(context).polylineRuta,
          trafficEnabled: false,
          myLocationEnabled: true,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: false,
          rotateGesturesEnabled: true,
          buildingsEnabled: false,
          compassEnabled: false,
          initialCameraPosition: camaraInicial,
          onMapCreated: (GoogleMapController controller) =>
              ProviderHomeScreen.googleMapController = controller),
    );
  }
}

class _DetallesRutaSolicitada extends StatelessWidget {
  _DetallesRutaSolicitada({Key? key, required this.size}) : super(key: key);

  void deslizamientoVertical(DragUpdateDetails dragUpdateDetails) {
    if (dragUpdateDetails.primaryDelta! <= -7) {
      listenerAnimacionPantalla.cambiarPantallaGrande();
    } else if (dragUpdateDetails.primaryDelta! >= 10) {
      listenerAnimacionPantalla.cambiarPantallaPequena();
    }
  }

  double obtenerAnchoPantalla() {
    double top = 0.0;

    if (listenerAnimacionPantalla.estadoPantalla ==
        EstadoPantalla.pantallaPequena) {
      top = size.height * 0.82;
    } else if (listenerAnimacionPantalla.estadoPantalla ==
        EstadoPantalla.pantallaGrande) {
      top = size.height * 0.15;
    }
    return top;
  }

  final Size size;

  final listenerAnimacionPantalla = ProviderAnimacionPantalla();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: listenerAnimacionPantalla,
        builder: (context, child) {
          return AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              height: size.height * 0.7,
              left: 0.0,
              right: 0.0,
              top: obtenerAnchoPantalla(),
              child: GestureDetector(
                onVerticalDragUpdate: deslizamientoVertical,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey, blurRadius: 5, spreadRadius: 1)
                      ],
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.only(
                            left: size.width * 0.27,
                            right: size.width * 0.27,
                            top: size.height * 0.01,
                            bottom: size.height * 0.03),
                        height: 6,
                      ),
                      Container(
                          margin: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Text("Distancia ${rutaApiGoogle.textoDistancia}",
                                  style: const TextStyle(fontSize: 22)),
                              Text(
                                  "Tiempo estimado ${rutaApiGoogle.textoDuracion}",
                                  style: const TextStyle(fontSize: 22)),
                              ListTile(
                                title:
                                    Text(detallesDireccionActual.nombreLugar),
                                subtitle: const Text("Mi ubicación"),
                              ),
                              ListTile(
                                  title: Text(
                                      detallesDireccionDestino.nombreLugar),
                                  subtitle: const Text("Mi destino")),
                            ],
                          )),
                      const Text(
                        'Pasajeros',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22),
                      ),
                      Center(
                        child: RatingBar.builder(
                          initialRating: 1,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 4,
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 4.0),
                          glow: false,
                          itemBuilder: (context, indice) =>
                              FloatingActionButton(
                            heroTag: 'floating-$indice',
                            onPressed: null,
                            child: Text(
                              '${indice + 1}',
                              style: const TextStyle(fontSize: 35),
                            ),
                          ),
                          onRatingUpdate: (cantidadPasajero) =>
                              cantidadPasajeros = cantidadPasajero.toInt(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 30, horizontal: 100),
                        child: ElevatedButton(
                            child: const Text("Solicitar taxi",
                                style: TextStyle(fontSize: 18)),
                            onPressed: () =>
                                ProviderHomeScreen.solicitarBusquedaTaxi()),
                      ),
                    ],
                  ),
                ),
              ));
        });
  }
}

class _RutaActual extends StatelessWidget {
  _RutaActual({Key? key, required this.size}) : super(key: key);

  void deslizamientoVertical(DragUpdateDetails dragUpdateDetails) {
    if (dragUpdateDetails.primaryDelta! <= -7) {
      listenerAnimacionPantalla.cambiarPantallaGrande();
    } else if (dragUpdateDetails.primaryDelta! >= 10) {
      listenerAnimacionPantalla.cambiarPantallaPequena();
    }
  }

  double obtenerAnchoPantalla() {
    double top = 0.0;

    if (listenerAnimacionPantalla.estadoPantalla ==
        EstadoPantalla.pantallaPequena) {
      top = size.height * 0.82;
    } else if (listenerAnimacionPantalla.estadoPantalla ==
        EstadoPantalla.pantallaGrande) {
      top = 0.0;
    }
    return top;
  }

  final Size size;

  final listenerAnimacionPantalla = ProviderAnimacionPantalla();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: listenerAnimacionPantalla,
        builder: (context, child) {
          return AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              height: size.height * 0.89,
              left: 0.0,
              right: 0.0,
              top: obtenerAnchoPantalla(),
              child: GestureDetector(
                onVerticalDragUpdate: deslizamientoVertical,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey, blurRadius: 5, spreadRadius: 1)
                      ],
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  child: rutaActual.status == "pagando"
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                              const Text(
                                'Evalua el servicio del taxista',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 40),
                              ),
                              RatingBar.builder(
                                initialRating: 1,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: false,
                                itemCount: 5,
                                itemPadding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                glow: false,
                                itemBuilder: (context, indice) => const Icon(
                                  Icons.star_border_purple500_rounded,
                                  size: 300,
                                  color: Colors.amber,
                                ),
                                onRatingUpdate: (cantidadPasajero) =>
                                    raitingCliente = cantidadPasajero,
                              ),
                              ElevatedButton(
                                child: const Text(
                                  "Aceptar",
                                  style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w300),
                                ),
                                onPressed: () async =>
                                    await ProviderHomeScreen.terminarRuta(),
                              )
                            ])
                      : ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: EdgeInsets.only(
                                  left: size.width * 0.27,
                                  right: size.width * 0.27,
                                  top: size.height * 0.01,
                                  bottom: size.height * 0.025),
                              height: 5,
                            ),
                            Container(
                                margin: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Text(
                                        "Distancia ${rutaActual.distanciaRuta}",
                                        style: const TextStyle(fontSize: 22)),
                                    Text(
                                        "Tiempo estimado ${rutaActual.duracionRuta}",
                                        style: const TextStyle(fontSize: 22)),
                                    Text("Costo \$${rutaActual.costoRuta}",
                                        style: const TextStyle(fontSize: 22)),
                                    _ListTileCustom(
                                      title: rutaActual.lugarInicio,
                                      subtitle: "Mi ubicación",
                                      size: size,
                                    ),
                                    _ListTileCustom(
                                      title: rutaActual.lugarDestino,
                                      subtitle: "Mi destino",
                                      size: size,
                                    ),
                                    _ListTileCustom(
                                      title: rutaActual.cantidadPasajeros
                                          .toString(),
                                      subtitle: "Cantidad de pasajeros",
                                      size: size,
                                    ),
                                    _ListTileCustom(
                                      title: rutaActual.telefonoTaxista,
                                      subtitle: "Telefono del taxista",
                                      size: size,
                                    ),
                                    _ListTileCustom(
                                      title: rutaActual.nombreTaxista,
                                      subtitle: "Nombre del taxista",
                                      size: size,
                                    ),
                                    _ListTileCustom(
                                      title:
                                          "${rutaActual.datosAutoTaxista.modelo} - ${rutaActual.datosAutoTaxista.color}\nPLACA > ${rutaActual.datosAutoTaxista.placa}",
                                      subtitle: "datos del auto del taxista",
                                      size: size,
                                    ),
                                  ],
                                )),
                            rutaActual.status == "aceptado"
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 50),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.share_location),
                                      label:
                                          const Text("Compartir mi ubicación"),
                                      onPressed: () async =>
                                          await ProviderHomeScreen
                                              .compartirRuta(),
                                    ),
                                  ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 50),
                              child: ElevatedButton(
                                  onPressed: rutaActual.status == "aceptado"
                                      ? () async => await ProviderHomeScreen
                                          .cancelarRutaActual()
                                      : rutaActual.status == "enRuta"
                                          ? () => showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  const DialogoProgreso(
                                                      titulo:
                                                          "Usted ya se encuentra en ruta hacia su destino, mientras esta en ruta puede compartir su ubicacion con alguien de confianza."))
                                          : () => () {},
                                  child: Text(rutaActual.status == "aceptado"
                                      ? "Cancelar ruta"
                                      : "En ruta")),
                            ),
                          ],
                        ),
                ),
              ));
        });
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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 1, spreadRadius: 0.5)
          ],
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }
}
