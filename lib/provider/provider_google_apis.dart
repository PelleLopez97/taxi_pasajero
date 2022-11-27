
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../global/variables_globales.dart';
import '../google_maps_api_key.dart';
import '../modelos/detalles_direccion_google_api.dart';
import '../modelos/ruta_api_google.dart';
import '../modelos/direccion_google_api.dart'; 

class ProviderGoogleApis extends ChangeNotifier {

  
  
  List<DireccionGoogleApi> _listaDirecciones = [];


  set listaDirecciones (List<DireccionGoogleApi> direcciones){

    _listaDirecciones = direcciones;

    notifyListeners();

  }

  List<DireccionGoogleApi> get listaDirecciones => _listaDirecciones; 


   static Future<void> buscarDireccionPorNombre(String nombreDireccion, BuildContext context) async {
  
      if (nombreDireccion.length > 4) {
        
        final uri = Uri.parse("https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$nombreDireccion&language=es-mx&location=${posicionActual.latitude},${posicionActual.longitude}&radius=10000&componentes=country:mx&key=$googleMapsApiKey");

        final response = await http.get(uri);
        final decodedData = json.decode(response.body);

        Provider.of<ProviderGoogleApis>(context,listen: false).listaDirecciones = (decodedData['predictions'] as List).map((place) => DireccionGoogleApi.fromJson(place)).toList();
      
      }
  }

   static Future<DetallesDireccionGoogleApi> encontrarDetallesDelLugarPorId(String placeId) async {
    
    final uri = Uri.parse("https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&languaje=es&key=$googleMapsApiKey");

    final response = await http.get(uri);
    final data = json.decode(response.body);
    return DetallesDireccionGoogleApi.fromJsonId(data);
  }


   static Future<DetallesDireccionGoogleApi> encontrarDetallesDelLugarPorCoordenadas() async {
    
     final uri = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?latlng=${posicionActual.latitude},${posicionActual.longitude}&key=$googleMapsApiKey");

     final response = await http.get(uri);
     final data = json.decode(response.body);
     return DetallesDireccionGoogleApi.fromJsonPosition(data);  

  }


  static Future<RutaApiGoogle> obtenerRuta() async {
   
    
  final latlngInicio = rutaActual.idTaxista == "no-data" ? LatLng(detallesDireccionActual.latitud, detallesDireccionActual.longitud) :  LatLng(rutaActual.coordenadasInicio.latitud, rutaActual.coordenadasInicio.longitud);
  final latlngDestino = rutaActual.idTaxista == "no-data" ? LatLng(detallesDireccionDestino.latitud, detallesDireccionDestino.longitud) :  LatLng(rutaActual.coordenadasDestino.latitud, rutaActual.coordenadasDestino.longitud);
    

    final uri = Uri.parse("https://maps.googleapis.com/maps/api/directions/json?origin=${latlngInicio.latitude},${latlngInicio.longitude}&destination=${latlngDestino.latitude},${latlngDestino.longitude}&key=$googleMapsApiKey");

    final response = await http.get(uri);

      final decodedData = json.decode(response.body);

      return RutaApiGoogle.fromJson(decodedData);      
   
  }

}

