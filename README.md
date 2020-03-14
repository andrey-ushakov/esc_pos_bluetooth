# esc_pos_bluetooth

[![Pub Version](https://img.shields.io/pub/v/esc_pos_bluetooth)](https://pub.dev/packages/esc_pos_bluetooth)

The library allows to print receipts using a Bluetooth printer. For WiFi/Ethernet printers, use [esc_pos_printer](https://github.com/andrey-ushakov/esc_pos_printer) library.

## Tested Printers
Here are some [printers tested with this library](printers.md). Please add your models you have tested to maintain and improve this library and help others to choose the right printer.


## Generate a Ticket

### Simple Ticket with Styles:
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

You can find more examples here: [esc_pos_utils](https://github.com/andrey-ushakov/esc_pos_utils).


## Print a Ticket

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

For a complete example, check the demo project `example/blue`.


## How to Help
* Test your printer and add it in the table: [Wifi/Network printer](https://github.com/andrey-ushakov/esc_pos_printer/blob/master/printers.md) or [Bluetooth printer](https://github.com/andrey-ushakov/esc_pos_bluetooth/blob/master/printers.md)
* Test and report bugs
* Share your ideas about what could be improved (code optimization, new features...)


## Test Print
<img src="https://github.com/andrey-ushakov/esc_pos_printer/blob/master/example/receipt.jpg?raw=true" alt="test receipt" height="500"/>
