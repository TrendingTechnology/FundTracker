import 'package:flutter/material.dart';
import 'package:fund_tracker/models/period.dart';
import 'package:fund_tracker/models/preferences.dart';
import 'package:fund_tracker/models/transaction.dart';
import 'package:fund_tracker/pages/transactions/transactionsList.dart';

class SearchService extends SearchDelegate {
  final List<Transaction> transactions;
  final Period currentPeriod;
  final Preferences prefs;
  final Function retrieveNewData;

  SearchService(
      this.transactions, this.currentPeriod, this.prefs, this.retrieveNewData);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    return null;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text('Start typing to query transactions.'));
    } else {
      final List<Transaction> searchedTransactions = transactions
          .where((tx) => tx.payee.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return TransactionsList(
        searchedTransactions,
        currentPeriod,
        prefs,
        retrieveNewData,
      );
    }
  }
}
