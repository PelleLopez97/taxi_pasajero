
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../global/variables_globales.dart';
import '../provider/provider_registro_screen.dart';

class RegistroScreen extends StatelessWidget {
  const RegistroScreen({Key? key}) : super(key: key);
  
  static const idScreen = "registration";

  @override
  Widget build(BuildContext context) {

    
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
               _FondoScreen(size: size,),
               _LogoInicioSesion(size: size,),
               _ContenedorFormularioUsuario(size: size)
        ],
      ),
    );
  }
}


class _LogoInicioSesion extends StatelessWidget {
  
  final Size size;
  
  const _LogoInicioSesion({
    required this.size,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text('Pide Taxi',style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold,fontStyle: FontStyle.italic),),
        Image.asset('assets/logo.png',  width: 80,height: 80,),
      ],
    );
  }
}

class _FondoScreen extends StatelessWidget {
  
  final Size size;

  const _FondoScreen({
    required this.size,
    Key? key,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
       decoration: const BoxDecoration(
         gradient: LinearGradient(
           stops: [
             0.5,
             0.8
           ],
           begin: Alignment.topCenter,
           end: Alignment.bottomCenter,
           colors: [
             Colors.amber,
            Colors.white
           ]
        )
              ),
            );
  }
}


class _ContenedorFormularioUsuario extends StatelessWidget {
  final Size size;
  const _ContenedorFormularioUsuario({
    required this.size,
    Key? key,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
              height: size.height * 0.65,
              margin: EdgeInsets.only(
                top: size.height * 0.20,
                left: size.width * 0.05, 
                right: size.width * 0.05),
              padding: const EdgeInsets.symmetric(horizontal:40),
               decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 10,
                                offset: Offset(0, 5)
                              )
                            ]
                          ),   
          child: const _FormularioDatosPersonales()
        )
    );
  }  
}

  class _FormularioDatosPersonales extends StatelessWidget {

  const _FormularioDatosPersonales({Key? key}) : super(key: key);
  
    @override
    Widget build(BuildContext context) {

      return Form(
        key: ProviderRegistroScreen.formStateKeyUsuario,
        autovalidateMode: AutovalidateMode.disabled,
            child:  Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextFormField(
                          controller: controllerNombreUsuario,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.name,
                          decoration: const InputDecoration(
                            hintText: 'Jose Castro Domingues', 
                            labelText: 'Nombre completo',
                            suffixIcon: Icon(Icons.people)),
                          validator: ( value ) {
                            return (value != null && value.isNotEmpty) ?  null : 'Nombre no valido';
                          },                      
                          ),
                        TextFormField(     
                          controller: controllerTelefonoUsuario,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '1234567890', 
                            labelText: 'Numero de telefono',
                            suffixIcon:  Icon(Icons.phone_in_talk)),
                          validator: ( value ) {
      
                            String pattern = '^(?:[+0]9)?[0-9]{10}\$';
                            RegExp regExp  = RegExp(pattern);
      
                            return regExp.hasMatch(value?? '') ? null : 'Numero no valido';
      
                          },                      
                          ),
                        TextFormField(      
                          controller: controllerCorreoUsuario,                  
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'usuario@gmail.com', 
                            labelText: 'Correo electronico', 
                            suffixIcon: Icon(Icons.alternate_email)),
                          validator: ( value ) {
      
                            String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                            RegExp regExp  = RegExp(pattern);
      
                            return regExp.hasMatch(value?? '') ? null : 'Correo no valido';
      
                          },                      
                          ),
      
                        TextFormField(
                          controller: controllerContrasenaUsuario,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.text,
                          obscureText: Provider.of<ProviderRegistroScreen>(context).contrasenaVisible,
                          decoration: InputDecoration(                            
                            suffixIcon: IconButton(onPressed: ()=> Provider.of<ProviderRegistroScreen>(context,listen: false).contrasenaVisible = !Provider.of<ProviderRegistroScreen>(context,listen: false).contrasenaVisible,
                                                   icon: Icon( Provider.of<ProviderRegistroScreen>(context,listen: false).contrasenaVisible ? Icons.visibility_off : Icons.visibility )),
                            hintText: '********',
                            labelText: 'Contraseña'),
                            validator: (value) => (value != null && value.length >= 6) ? null : 'La contraseña debe ser mayor o igual a 6 caracteres',
                           ),
                          
                        ElevatedButton(                      
                         child: const Text("Crear cuenta", style: TextStyle(fontSize: 18.0, fontFamily: "Brand Bold")),
                         onPressed: ()=> ProviderRegistroScreen.validarFormularioUsuario()  ? ProviderRegistroScreen.registrarUsuario(context) : null), 
                      ],)
      );
    }

  

  }

  