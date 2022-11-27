
class TaxistaDisponible {
  String id       = 'no-data';
  double latitud  = 0.0;
  double longitud = 0.0;

  TaxistaDisponible(this.id, this.latitud, this.longitud);

  TaxistaDisponible.fromJson(Map<String,dynamic> dataMap, key){
    id = key;
    latitud = dataMap["lat"];
    longitud = dataMap["lng"];
  }

}
