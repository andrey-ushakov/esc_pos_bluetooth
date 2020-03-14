# esc_pos_bluetooth

The library allows to print receipts using a Bluetooth printer. For WiFi/Ethernet printers, use [esc_pos_printer](https://github.com/andrey-ushakov/esc_pos_printer) library.

[[pub.dev page]](https://pub.dev/packages/esc_pos_bluetooth)
| [[Documentation]](https://pub.dev/documentation/esc_pos_bluetooth/latest/)

## Tested Printers
Here are some [printers tested with this library](printers.md). Please add your models you have tested to maintain and improve this library and help others to choose the right printer.

## Main Features
* Android / iOS support
* Simple text printing using *text* method
* Tables printing using *row* method
* Text styling:
  * size, align, bold, reverse, underline, different fonts, turn 90°
* Print images
* Print barcodes
  * UPC-A, UPC-E, JAN13 (EAN13), JAN8 (EAN8), CODE39, ITF (Interleaved 2 of 5), CODABAR (NW-7), CODE128
* Paper cut (partial, full)
* Beeping (with different duration)
* Paper feed, reverse feed

**Note**: Your printer may not support some of the presented features (especially for underline styles, partial/full paper cutting, reverse feed, ...).

## Getting started: Generate a Ticket

### Simple ticket:
```dart
Ticket testTicket() {
  final Ticket ticket = Ticket(PaperSize.mm80);

  ticket.text(
      'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
  ticket.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
      styles: PosStyles(codeTable: PosCodeTable.westEur));
  ticket.text('Special 2: blåbærgrød',
      styles: PosStyles(codeTable: PosCodeTable.westEur));

  ticket.text('Bold text', styles: PosStyles(bold: true));
  ticket.text('Reverse text', styles: PosStyles(reverse: true));
  ticket.text('Underlined text',
      styles: PosStyles(underline: true), linesAfter: 1);
  ticket.text('Align left', styles: PosStyles(align: PosAlign.left));
  ticket.text('Align center', styles: PosStyles(align: PosAlign.center));
  ticket.text('Align right',
      styles: PosStyles(align: PosAlign.right), linesAfter: 1);

  ticket.text('Text size 200%',
      styles: PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ));

  ticket.feed(2);
  ticket.cut();
  return ticket;
}
```

### Print a table row:

```dart
ticket.row([
    PosColumn(
      text: 'col3',
      width: 3,
      styles: PosStyles(align: PosAlign.center, underline: true),
    ),
    PosColumn(
      text: 'col6',
      width: 6,
      styles: PosStyles(align: PosAlign.center, underline: true),
    ),
    PosColumn(
      text: 'col3',
      width: 3,
      styles: PosStyles(align: PosAlign.center, underline: true),
    ),
  ]);
```

### Print an image:

This package implements 3 ESC/POS functions:
* `ESC *` - print in column format
* `GS v 0` - print in bit raster format (obsolete)
* `GS ( L` - print in bit raster format

Note that your printer may support only some of the above functions.

```dart
import 'dart:io';
import 'package:image/image.dart';

final ByteData data = await rootBundle.load('assets/logo.png');
final Uint8List bytes = data.buffer.asUint8List();
final Image image = decodeImage(bytes);
// Using `ESC *`
ticket.image(image);
// Using `GS v 0` (obsolete)
ticket.imageRaster(image);
// Using `GS ( L`
ticket.imageRaster(image, imageFn: PosImageFn.graphics);
```

### Print a barcode:

```dart
final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
ticket.barcode(Barcode.upcA(barData));
```

### Print a QR Code:

To print a QR Code, add [qr_flutter](https://pub.dev/packages/qr_flutter) and [path_provider](https://pub.dev/packages/path_provider) as a dependency in your `pubspec.yaml` file.
```dart
String qrData = "google.com";
const double qrSize = 200;
try {
  final uiImg = await QrPainter(
    data: qrData,
    version: QrVersions.auto,
    gapless: false,
  ).toImageData(qrSize);
  final dir = await getTemporaryDirectory();
  final pathName = '${dir.path}/qr_tmp.png';
  final qrFile = File(pathName);
  final imgFile = await qrFile.writeAsBytes(uiImg.buffer.asUint8List());
  final img = decodeImage(imgFile.readAsBytesSync());

  ticket.image(img);
} catch (e) {
  print(e);
}
```

## Getting Started (Bluetooth printer)

```dart
PrinterBluetoothManager printerManager = PrinterBluetoothManager();

printerManager.scanResults.listen((printers) async {
  // store found printers
});
printerManager.startScan(Duration(seconds: 4));

// ...

printerManager.selectPrinter(printer);
final PosPrintResult res = await printerManager.printTicket(testTicket());

print('Print result: ${res.msg}');
```

For more details, check the demo project *example/blue*.

## Test print
<img src="https://github.com/andrey-ushakov/esc_pos_printer/blob/master/example/receipt.jpg?raw=true" alt="test receipt" height="500"/>

## Support
If this package was helpful, a cup of coffee would be highly appreciated :)

[<img src="https://az743702.vo.msecnd.net/cdn/kofi2.png?v=2" width="200">](https://ko-fi.com/andreydev)