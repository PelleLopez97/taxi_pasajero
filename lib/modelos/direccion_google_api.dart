
class DireccionGoogleApi {
  String textoSecundario = 'sin informacion';
  String textoPrincipal = 'sin informacion';
  String lugarId = 'sin informacion';

  DireccionGoogleApi(this.textoSecundario, this.textoPrincipal, this.lugarId);

  DireccionGoogleApi.fromJson(Map<String, dynamic> dataMap) {
    lugarId = dataMap['place_id'];
    textoPrincipal = dataMap['structured_formatting']['main_text'];
    textoSecundario = dataMap['description'];
  }
}

