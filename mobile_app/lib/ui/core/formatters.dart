import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static String formatCurrency(num amount) {
    return _currencyFormat.format(amount).trim();
  }

  static String formatNumber(num amount) {
    final int val = amount.toInt();
    return val.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  static double parseCurrency(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final cleanStr = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanStr.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final number = int.tryParse(cleanStr) ?? 0;
    final formatted = number.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
