/*
 * esc_pos_bluetooth
 * Created by Andrey Ushakov
 * 
 * Copyright (c) 2020. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

class PosPrintResult {
  const PosPrintResult._internal(this.value, this.msg);

  final int value;
  final String msg;

  static const success = PosPrintResult._internal(1, 'Success');
  static const timeout =
      PosPrintResult._internal(2, 'Error. Printer connection timeout');
  static const printerNotSelected =
      PosPrintResult._internal(3, 'Error. Printer not selected');
  static const ticketEmpty =
      PosPrintResult._internal(4, 'Error. Ticket is empty');
  static const printInProgress =
      PosPrintResult._internal(5, 'Error. Another print in progress');
  static const scanInProgress =
      PosPrintResult._internal(6, 'Error. Printer scanning in progress');
}
