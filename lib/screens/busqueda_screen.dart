import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../global/variables_globales.dart';
import '../modelos/direccion_google_api.dart';
import '../provider/provider_google_apis.dart';
import '../provider/provider_home_screen.dart';

class BusquedaScreen extends SearchDelegate{
  List<String> nombreLugaresHistorial = [];


  @override
  // ignore: overridden_fields
  String? searchFieldLabel = '¿Hacia donde . . . ?' ;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [  
      IconButton(
        icon: const Icon(Icons.delete), 
        onPressed: ()=> query = '')
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: ()=> Navigator.pop(context),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
      return Provider.of<ProviderGoogleApis>(context,listen: false).listaDirecciones.isEmpty ? const Center(child: CircularProgressIndicator()) 
                               : ListView.builder(
                                 scrollDirection: Axis.vertical,
                                 physics: const NeverScrollableScrollPhysics(),
                                 itemBuilder: (context, index) {
                                   return _DireccionItem(direccionGoogleApi: Provider.of<ProviderGoogleApis>(context,listen: false).listaDirecciones[index]);
                                 },
                                 itemCount: Provider.of<ProviderGoogleApis>(context,listen: false).listaDirecciones.length);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    
      ProviderGoogleApis.buscarDireccionPorNombre(query, context);

       return Provider.of<ProviderGoogleApis>(context,listen: false).listaDirecciones.isEmpty ? const Center(child: CircularProgressIndicator()) 
                               : ListView.builder(
                                 scrollDirection: Axis.vertical,
                                 physics: const NeverScrollableScrollPhysics(),
                                 itemBuilder: (context, index) {
                                   return _DireccionItem(direccionGoogleApi: Provider.of<ProviderGoogleApis>(context,listen: false).listaDirecciones[index]);
                                 },
                                 itemCount: Provider.of<ProviderGoogleApis>(context,listen: false).listaDirecciones.length);
  }
}



class _DireccionItem extends StatelessWidget{
  final DireccionGoogleApi direccionGoogleApi;
  const _DireccionItem({Key? key, required this.direccionGoogleApi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10,horizontal: 5),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              // spreadRadius: 0,
              blurRadius: 1
            )
          ]
        ),        
        child: ListTile(
          title: Text(
            direccionGoogleApi.textoPrincipal,
            style: const TextStyle(overflow: TextOverflow.ellipsis),
          ),
          subtitle: Text(
            direccionGoogleApi.textoSecundario,
            style: const TextStyle(overflow: TextOverflow.visible),
          ),
          onTap: ()async{
                  detallesDireccionDestino = await ProviderGoogleApis.encontrarDetallesDelLugarPorId( direccionGoogleApi.lugarId);
                  await ProviderHomeScreen.permisoUbicacion();
                  detallesDireccionActual  = await ProviderGoogleApis.encontrarDetallesDelLugarPorCoordenadas();
                  detallesDireccionActual.latitud = posicionActual.latitude;
                  detallesDireccionActual.longitud = posicionActual.longitude;
                  Navigator.pop(context,"busqueda-completa");
        } 
        )
    );
  }
}
