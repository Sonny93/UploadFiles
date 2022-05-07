import 'dart:convert';
import 'dart:io' as Io;
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

var client = http.Client();

void main() => runApp(MyApp());

var _httpProtocol = 'http://';
var endpoint = '192.168.200.242:3000';

class MyApp extends StatelessWidget {
  @override
  Widget build(context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        Login.routeName: (context) => Login(),
        fileList.routeName: (context) => fileList()
      }
    );
  }
}

class Login extends StatefulWidget {
  static var routeName = '/';
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  bool isBtnEnabled = true;
  var fields = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text('Se connecter'),
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Entrez votre email'),
                    validator: (value) {
                      if (value.isEmpty)
                        return 'Ce champ ne peut être vide';
                      RegExp regex = new RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
                      if (!regex.hasMatch(value))
                        return 'Ce champ doit contenir un email';
                      fields['email'] = value;
                      return null;
                    }
                  ),
                  TextFormField(
                    autocorrect: false,
                    enableSuggestions: false,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Entrez votre mot de passe'),
                    validator: (value) {
                      if (value.isEmpty)
                        return 'Ce champ ne peut être vide';
                      fields['password'] = value;
                      return null;
                    }
                  ),
                  RaisedButton(
                    child: Text(isBtnEnabled ? 'Connexion' : 'Connexion...'),
                    onPressed: isBtnEnabled ? () {
                      print(_formKey);
                      if (!isBtnEnabled)
                        return print('cant try to login');
                      setState(() => isBtnEnabled = false);
                      
                      if (_formKey.currentState.validate()) {
                        print('try to login');
                        Future.delayed(Duration(seconds: 1), () => setState(() {
                          isBtnEnabled = true;
                        }));
                        print(fields);
                        client.post(new Uri.http(endpoint, "/login"), body: {
                          'email': fields['email'],
                          'password': fields['password']
                        }).then((value) {
                            var parsed = jsonDecode(value.body);
                            if (parsed['status'] != 200) {
                              Fluttertoast.showToast(
                                  msg: parsed['message'],
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0
                              );
                            } else {
                              Fluttertoast.showToast(
                                  msg: parsed['message'],
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                  fontSize: 16.0
                              );
                              Navigator.pushNamedAndRemoveUntil(context, fileList.routeName, (route) => false);
                            }
                            return print(parsed);
                        }).catchError((error) => print(error));
                      }
                    } : null
                  )
                ]
              )
            ))
          )
        ]
      )
    );
  }
}

class fileList extends StatefulWidget {
  static var routeName = '/fileList';
  @override
  _fileListState createState() => _fileListState();
}

class _fileListState extends State<fileList> {
  var elements = [];
  @override
  void initState() {
    client.get(new Uri.http(endpoint, "/files")).then((value) {
        var parsed = jsonDecode(value.body);
        if (parsed['status'] != 200) {
          Fluttertoast.showToast(
              msg: parsed['message'],
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0
          );
        } else {
          var contents = parsed['contents'];
          setState(() => elements = contents);
        }
        return print(parsed);
    }).catchError((error) => print(error));
    super.initState();
  }
	@override
	Widget build(BuildContext context) {
    var elementsLength = elements.length;
		return MaterialApp(
			home: Scaffold(
				appBar: AppBar(title: Text('Upload Files - $elementsLength file' + (elementsLength > 1 ? 's' : ''))),
				body: elements.isNotEmpty ? ListView.separated(
					itemCount: elements.length,
					itemBuilder: (context, position) {
            var url = elements[position]['url'];
            return ListTile(
              title: Image(image: NetworkImage('$_httpProtocol$endpoint$url')), 
              onTap: () {
                // open element in dedicated widget
              }
            );
          },
					separatorBuilder: (context, position) => Divider(),
				) : Center(child: Text('There is no content')),
				floatingActionButton: FloatingActionButton(
					onPressed: () async {
            var file = await ImagePicker().getImage(source: ImageSource.gallery); 
            final filebytes = Io.File(file.path).readAsBytesSync();
            var imageBase64 = base64Encode(filebytes);
            var filePathSplitted = file.path.split('/');
            var fileName = filePathSplitted[filePathSplitted.length - 1];
            if (file == null)
              return;

            client.post(
              new Uri.http(endpoint, "/postimage"),
              body: { 
                "file": jsonEncode({
                  "data": imageBase64,
                  "name": fileName
                })
              }
            ).then((value) {
              var parsed = jsonDecode(value.body);
              if (parsed['status'] != 200) {
                Fluttertoast.showToast(
                    msg: parsed['message'],
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0
                );
              } else {
                Fluttertoast.showToast(
                    msg: parsed['message'],
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0
                );
                setState(() => elements.add(parsed['file']));
              }
              return print(parsed);
            }).catchError((error) => print(error));
					}, 
					child: Icon(Icons.add)
				)
			)
		);
	}
}

class InfoOfElement extends StatefulWidget {
  @override
  _InfoOfElementState createState() => _InfoOfElementState();
}

class _InfoOfElementState extends State<InfoOfElement> {
  @override
  Widget build(BuildContext context) {
	return Scaffold(
		appBar: AppBar(title: Text('Upload File - more infos')),
		body: Text('yo')
	);
  }
}