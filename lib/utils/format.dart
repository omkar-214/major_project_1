import 'package:intl/intl.dart';

final NumberFormat _moneyNoDecimal = NumberFormat.currency(
  locale: "en_IN",
  symbol: "₹",
  decimalDigits: 0,
);

final NumberFormat _moneyWithDecimal = NumberFormat.currency(
  locale: "en_IN",
  symbol: "₹",
  decimalDigits: 2,
);

String money(double value, {bool decimals = false}) {
  if (decimals) {
    return _moneyWithDecimal.format(value);
  }
  return _moneyNoDecimal.format(value);
}

String fmtDate(DateTime date) {
  return DateFormat("d MMM yyyy").format(date);
}

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String dueLabel(DateTime due) {
  int days = dateOnly(due).difference(dateOnly(DateTime.now())).inDays;

  if (days < 0) {
    int overdue = -days;
    if (overdue == 1) {
      return "1 day overdue";
    }
    return "$overdue days overdue";
  }
  if (days == 0) {
    return "Due today";
  }
  if (days == 1) {
    return "Due in 1 day";
  }
  return "Due in $days days";
}