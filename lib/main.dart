import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isGranted = true;
  String fileName = "demoFile.pdf";
  String pdfUrl = "https://www.clickdimensions.com/links/TestPDFfile.pdf";
  String newPdfUrl = "https://d1rz6k04k2ybb2.cloudfront.net/CengageIndia/9788131515068/pdf/YdFLSjgc3m/encrypt.pdf";

  Future<Directory?> get getAppDir async {
    final appDocDir = await getExternalStorageDirectory();
    return appDocDir;
  }

  Future<Directory> get getExternalVisibleDir async {
    var directoryData = getAppDir;
    debugPrint("The data is -------- :  ${directoryData}");

    if (await Directory(
            '/storage/emulated/0/Android/data/com.example.pdf_decrypt/files')                          //  /storage/emulated/0/Android/data/com.example.pdf_decrypt/files
        .exists()) {
      final externalDir = Directory(
          '/storage/emulated/0/Android/data/com.example.pdf_decrypt/files');
      return externalDir;
    } else {
      await Directory(
              '/storage/emulated/0/Android/data/com.example.pdf_decrypt/files')
          .create(recursive: true);
      final externalDir = Directory(
          '/storage/emulated/0/Android/data/com.example.pdf_decrypt/files');
      return externalDir;
    }
  }

  requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      PermissionStatus result = await Permission.storage.request();
      if (result.isGranted) {
        setState(() {
          _isGranted = true;
        });
      } else {
        _isGranted = false;
      }
    }
  }

  Future<String> _writeData(dataToWrite, fileNameWithPath) async {
    debugPrint("Writing Data ...");
    File f = File(fileNameWithPath);
    await f.writeAsBytes(dataToWrite);
    return f.absolute.toString();
  }

  Future<Uint8List> _readData(fileNameWithPath) async {
    debugPrint("Reading data ...");
    File f = File(fileNameWithPath);
    return await f.readAsBytes();
  }

  Future<List<int>> _decryptData(encData) async {
    debugPrint("File decryption in progress ... ");
    enc.Encrypted encrypted = enc.Encrypted(encData);
    return MyEncrypt.myCryptor.decryptBytes(encrypted,iv: MyEncrypt.myIv);
  }

  _encryptData(plainString) {
    debugPrint("Encrypting file");
    final encrypted =
        MyEncrypt.myCryptor.encryptBytes(plainString,iv: MyEncrypt.myIv);
    debugPrint("----------------------  1     --------------------");
    debugPrint("Encrypted key is :  ${MyEncrypt.myKey.base64}");
    debugPrint("Encrypted IV is :  ${MyEncrypt.myIv.base64}");
    debugPrint("Encrypted encryptor is :  ${MyEncrypt.myCryptor}");
    return encrypted.bytes;
  }
    _getNewNormalFile(String path,Directory d, filename) async{
      if (await canLaunchUrlString(path)) {
        debugPrint("Data Downloading ...");
        var resp = await http.get(Uri.parse(path));
      /*  var encResult = resp.bodyBytes;
        String p = await _writeData(encResult, d.path + '/$filename.aes');
        debugPrint("file download  successfully : $p");
        Uint8List encData = await _readData(d.path + '/$filename.aes');           */

        var plainData = await _decryptData(resp.bodyBytes);
        String pathNew = await _writeData(plainData, d.path + '/$filename');
        // await File(d.path + '/$filename.aes').delete();
        debugPrint("File decrypted successfully : $pathNew");

      } else {
        debugPrint("Can't Launch Url. ");
      }
    }
  _getNormalFile(Directory d, filename) async {
    Uint8List encData = await _readData(d.path + '/$filename.aes');
    var plainData = await _decryptData(encData);
    String p = await _writeData(plainData, d.path + '/$filename');
   // await File(d.path + '/$filename.aes').delete();
    debugPrint("File decrypted successfully : $p");
  }

  _downloadAndCreate(String path, Directory d, filename) async {
    if (await canLaunchUrlString(path)) {
      debugPrint("Data Downloading ...");
      var resp = await http.get(Uri.parse(path));
      var encResult = _encryptData(resp.bodyBytes);
      String p = await _writeData(encResult, d.path + '/$filename.aes');
      debugPrint("file encrypted successfully : $p");
    } else {
      debugPrint("Can't Launch Url. ");
    }
  }

  @override
  Widget build(BuildContext context) {
    requestStoragePermission();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton(
                onPressed: () async {
                  if (_isGranted) {
                    Directory d = await getExternalVisibleDir;
                    _downloadAndCreate(pdfUrl, d, fileName);
                  } else {
                    debugPrint("No Permission granted");
                    requestStoragePermission();
                  }
                },
                child: const Text('Download & Encrypt')),
            OutlinedButton(
                onPressed: () async {
                  if (_isGranted) {
                    Directory d = await getExternalVisibleDir;
                   _getNewNormalFile(newPdfUrl, d, fileName);
                  } else {
                    debugPrint("No Permission granted");
                    requestStoragePermission();
                  }
                },
                child: const Text('Decrypt Without Download')),
            OutlinedButton(
                onPressed: () async {
                  if (_isGranted) {
                    Directory d = await getExternalVisibleDir;
                    _getNormalFile(d, fileName);
                  } else {
                    debugPrint("No Permission granted");
                    requestStoragePermission();
                  }
                },
                child: const Text('Download & Decrypt')),
          ],
        ),
      ),
    );
  }
}

class MyEncrypt {
  static final myKey = enc.Key.fromBase16('abe6e1ffcfda945fa6fa2dbc89750372');
  // enc.Key.fromSecureRandom(16); //   enc.Key.fromUtf8('263BC60258FF4876');
  static final myIv = enc.IV.fromBase16('d981d69128e02dd0984c61a8e88f4d13');
  // enc.IV.fromSecureRandom(16);  //  enc.IV.fromUtf8('KartikSignal987');
  static final myCryptor = enc.Encrypter(enc.AES(myKey,mode: enc.AESMode.cbc));
}
