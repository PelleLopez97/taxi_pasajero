class DetallesDireccionGoogleApi {
 String nombreLugar='Sin nombre de lugar';
 double latitud=0.0;
 double longitud=0.0;

DetallesDireccionGoogleApi({
  required this.latitud,
  required this.longitud});

  DetallesDireccionGoogleApi.fromJsonId(Map<String, dynamic> dataMap) {
    nombreLugar = dataMap['result']['formatted_address'];
    latitud     = dataMap['result']['geometry']['location']['lat'];
    longitud    = dataMap['result']['geometry']['location']['lng'];
  }
  DetallesDireccionGoogleApi.fromJsonPosition(Map<String, dynamic> dataMap) {
    nombreLugar = dataMap['results'][0]['formatted_address'];
  }
}