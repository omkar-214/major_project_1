import 'package:vaultly/models/models.dart';
import 'package:vaultly/utils/format.dart';

class InterestService {
  static DateTime endOf(TxModel tx) {
    return tx.settledAt ?? DateTime.now();
  }

  static double _calc(TxModel tx, int days) {
    if (days <= 0) return 0;

    double factor;
    if (tx.rateType == "monthly") {
      factor = days / 30.0;
    } else {
      factor = days / 365.0;
    }

    return tx.amount * tx.rate / 100 * factor;
  }

  static double between(TxModel tx, DateTime from, DateTime to, {DateTime? asOf}) {
    DateTime end = tx.settledAt ?? asOf ?? DateTime.now();

    DateTime start;
    if (from.isAfter(tx.startDate)) {
      start = from;
    } else {
      start = tx.startDate;
    }

    DateTime endDate;
    if (to.isBefore(end)) {
      endDate = to;
    } else {
      endDate = end;
    }

    int days = dateOnly(endDate).difference(dateOnly(start)).inDays;
    return _calc(tx, days);
  }

  static double tillToday(TxModel tx) {
    return between(tx, tx.startDate, DateTime(3000));
  }

  static double tillDue(TxModel tx) {
    DateTime? due = tx.dueDate;
    if (due == null) {
      return tillToday(tx);
    }
    int days = dateOnly(due).difference(dateOnly(tx.startDate)).inDays;
    return _calc(tx, days);
  }
}