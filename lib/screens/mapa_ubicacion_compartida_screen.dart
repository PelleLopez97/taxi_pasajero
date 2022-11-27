
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../global/variables_globales.dart';
import '../provider/provider_mapa_compartir_ubicacion_screen.dart';

class MapaUbicacionCompartidaScreen extends StatefulWidget {
  const MapaUbicacionCompartidaScreen({Key? key}) : super(key: key);
  static const idScreen = "mapa_ubicacion_compartida";

  @override
  State<MapaUbicacionCompartidaScreen> createState() => _MapaUbicacionCompartidaScreenState();
}

class _MapaUbicacionCompartidaScreenState extends State<MapaUbicacionCompartidaScreen> {

  @override
  void initState() {
    super.initState();
    
    ProviderMapaCompartirUbicacionScreen.permisoUbicacion(); 

  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Scaffold(

      body: Stack(
        children: [
          GoogleMap(
                    
                    mapType: MapType.normal,
                    markers: Provider.of<ProviderMapaCompartirUbicacionScreen>(context).listaMarkers,
                    polylines: Provider.of<ProviderMapaCompartirUbicacionScreen>(context,listen: false).polylineRuta,
                    trafficEnabled: false,
                    myLocationEnabled: true,
                    zoomGesturesEnabled: true,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                    rotateGesturesEnabled: true,
                    buildingsEnabled: false,
                    compassEnabled: false,
                    initialCameraPosition: camaraInicial,
                    onMapCreated: (GoogleMapController controller) => ProviderMapaCompartirUbicacionScreen.googleMapController = controller
                  ),
          Positioned(
            top: size.height * 0.05,
            right: size.width * 0.01,
            left: size.width * 0.01,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 3,
                    spreadRadius: 1
                  )
                ]
              ),
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: "Pega aqui el enlace para encontrar la ruta...",
                ),
                onFieldSubmitted: (url) => ProviderMapaCompartirUbicacionScreen.consultarRutaCompartida( url, context),
              ),
            ),
          )        

        ],
      ),

    );
  }
}