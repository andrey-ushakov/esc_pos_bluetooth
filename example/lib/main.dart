import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESC Pos Bluetooth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'ESC Pos Bluetooth'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  TextEditingController controller = TextEditingController(text: '66:32:8B:D7:76:E2');

  String message = '';

  void _printTest(String macAddress) async {
    printerManager.selectMacAddress(macAddress);

    const PaperSize paper = PaperSize.mm80;
    final CapabilityProfile profile = await CapabilityProfile.load();
    final Generator ticket = Generator(paper, profile);

    // DEMO RECEIPT
    final receipt = await demoReceipt(ticket);
    final response = await printerManager.printTicket(receipt);
    setState(() {
      message = response.msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Input mac address',
            ),
            TextFormField(
              controller: controller,
            ),
            const SizedBox(height: 4),
            Text(
              message,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _printTest(controller.text),
        tooltip: 'Print',
        child: const Icon(Icons.print),
      ),
    );
  }
}

Future<List<int>> demoReceipt(Generator generator) async {
  List<int> bytes = [];

  // Print image
  // final ByteData data = await rootBundle.load('assets/rabbit_black.jpg');
  // final Uint8List imageBytes = data.buffer.asUint8List();
  // final img.Image image = img.decodeImage(imageBytes)!;
  // bytes += generator.image(image);

  // Print QR Code using native function
  // bytes += generator.hr();
  // bytes += generator.qrcode('example.com');

  bytes += generator.hr();
  bytes += generator.text(
    'GROCERYLY',
    styles: const PosStyles(
      align: PosAlign.center,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ),
    linesAfter: 1,
  );
  bytes += generator.text(
    '889  Watson Lane',
    styles: const PosStyles(align: PosAlign.center),
  );
  bytes += generator.text(
    'New Braunfels, TX',
    styles: const PosStyles(align: PosAlign.center),
  );
  bytes += generator.text(
    'Tel: 830-221-1234',
    styles: const PosStyles(align: PosAlign.center),
  );
  bytes += generator.text(
    'Web: www.example.com',
    styles: const PosStyles(align: PosAlign.center),
    linesAfter: 1,
  );

  bytes += generator.hr();
  bytes += generator.row([
    PosColumn(text: 'Qty', width: 1),
    PosColumn(text: 'Item', width: 7),
    PosColumn(
      text: 'Price',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
    PosColumn(
      text: 'Total',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);
  bytes += generator.row([
    PosColumn(text: '2', width: 1),
    PosColumn(text: 'ONION RINGS', width: 7),
    PosColumn(
      text: '0.99',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
    PosColumn(
      text: '1.98',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);
  bytes += generator.row([
    PosColumn(text: '1', width: 1),
    PosColumn(text: 'PIZZA', width: 7),
    PosColumn(
      text: '3.45',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
    PosColumn(
      text: '3.45',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);
  bytes += generator.row([
    PosColumn(text: '1', width: 1),
    PosColumn(text: 'SPRING ROLLS', width: 7),
    PosColumn(
      text: '2.99',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
    PosColumn(
      text: '2.99',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);
  bytes += generator.row([
    PosColumn(text: '3', width: 1),
    PosColumn(text: 'CRUNCHY STICKS', width: 7),
    PosColumn(
      text: '0.85',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
    PosColumn(
      text: '2.55',
      width: 2,
      styles: const PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.hr();
  bytes += generator.row([
    PosColumn(
      text: 'TOTAL',
      width: 6,
      styles: const PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ),
    PosColumn(
      text: '\$10.97',
      width: 6,
      styles: const PosStyles(
        align: PosAlign.right,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ),
  ]);

  bytes += generator.hr(ch: '=', linesAfter: 1);
  bytes += generator.row([
    PosColumn(
      text: 'Cash',
      width: 7,
      styles: const PosStyles(align: PosAlign.right, width: PosTextSize.size2),
    ),
    PosColumn(
      text: '\$15.00',
      width: 5,
      styles: const PosStyles(align: PosAlign.right, width: PosTextSize.size2),
    ),
  ]);
  bytes += generator.row([
    PosColumn(
      text: 'Change',
      width: 7,
      styles: const PosStyles(align: PosAlign.right, width: PosTextSize.size2),
    ),
    PosColumn(
      text: '\$4.03',
      width: 5,
      styles: const PosStyles(align: PosAlign.right, width: PosTextSize.size2),
    ),
  ]);

  bytes += generator.feed(2);
  bytes += generator.text(
    'Thank you!',
    styles: const PosStyles(align: PosAlign.center, bold: true),
  );

  final now = DateTime.now();
  final formatter = DateFormat('MM/dd/yyyy H:m');
  final String timestamp = formatter.format(now);
  bytes += generator.text(
    timestamp,
    styles: const PosStyles(align: PosAlign.center),
    linesAfter: 2,
  );

  generator.feed(2);
  generator.cut();
  return bytes;
}
