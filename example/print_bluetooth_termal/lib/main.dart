import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:oktoast/oktoast.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Bluetooth demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Bluetooth demo'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];

  @override
  void initState() {
    super.initState();

    printerManager.scanResults.listen((devices) async {
      // print('UI: Devices found ${devices.length}');
      setState(() {
        _devices = devices;
      });
    });
  }

  void _startScanDevices() {
    setState(() {
      _devices = [];
    });
    printerManager.startScan(Duration(seconds: 4));
  }

  void _stopScanDevices() {
    printerManager.stopScan();
  }

  Future<List<int>> demoReceipt(PaperSize paper) async {
    //final Ticket ticket = Ticket(paper);

    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> ticket = [];

    // Print image
    final ByteData data = await rootBundle.load('assets/rabbit_black.jpg');
    final Uint8List bytes = data.buffer.asUint8List();
    final Image image = decodeImage(bytes);
    // ticket.image(image);
    ticket += generator.text(" "); //=============================> !!!! IMPORTANT

    ticket += generator.text("TESTING PRINT",
      styles: PosStyles(
        align: PosAlign.center,
        bold: true
      )
    );

    ticket += generator.hr();

    ticket += generator.text("Items : ",
        styles: PosStyles(
            align: PosAlign.left,
            bold: true
        )
    );

    ticket += generator.text("Latop 1 ",
        styles: PosStyles(
            align: PosAlign.right,
            bold: true
        )
    );
    ticket += generator.text("Latop 2 ",
        styles: PosStyles(
            align: PosAlign.right,
            bold: true
        )
    );

    
    ticket += generator.cut();
    return ticket;
  }

  void _testPrint(PrinterBluetooth printer) async {
    printerManager.selectPrinter(printer);

    // TODO Don't forget to choose printer's paper
    const PaperSize paper = PaperSize.mm58;

    // TEST PRINT
    // final PosPrintResult res =
    // await printerManager.printTicket(await testTicket(paper));

    // DEMO RECEIPT
    final PosPrintResult res =
    await printerManager.printTicket(await demoReceipt(paper));

    showToast(res.msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
          itemCount: _devices.length,
          itemBuilder: (BuildContext context, int index) {
            if(_devices[index].name.isNotEmpty || _devices[index].name != ""){
              return InkWell(
                onTap: () => _testPrint(_devices[index]),
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 60,
                      padding: EdgeInsets.only(left: 10),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.print),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(_devices[index].name ?? ''),
                                Text(_devices[index].address ?? ''),
                                Text(_devices[index].type.toString() ?? ''),
                                Text(
                                  'Click to print a test receipt',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(),
                  ],
                ),
              );
            }

            return Container();

          }),
      floatingActionButton: StreamBuilder<bool>(
        stream: printerManager.isScanningStream,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: _stopScanDevices,
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
              child: Icon(Icons.search),
              onPressed: _startScanDevices,
            );
          }
        },
      ),
    );
  }
}
