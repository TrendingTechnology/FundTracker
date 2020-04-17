import 'package:community_material_icon/community_material_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fund_tracker/models/category.dart';
import 'package:fund_tracker/models/period.dart';
import 'package:fund_tracker/models/preferences.dart';
import 'package:fund_tracker/models/transaction.dart';
import 'package:fund_tracker/pages/home/filter.dart';
import 'package:fund_tracker/pages/statistics/statistics.dart';
import 'package:fund_tracker/pages/transactions/transactionForm.dart';
import 'package:fund_tracker/pages/transactions/transactionsList.dart';
import 'package:fund_tracker/services/databaseWrapper.dart';
import 'package:fund_tracker/pages/home/mainDrawer.dart';
import 'package:fund_tracker/services/fireDB.dart';
import 'package:fund_tracker/services/localDB.dart';
import 'package:fund_tracker/services/recurringTransactions.dart';
import 'package:fund_tracker/services/search.dart';
import 'package:fund_tracker/shared/library.dart';
import 'package:fund_tracker/shared/components.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  final FirebaseUser user;

  Home({this.user});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  PageController _pageController = PageController();

  List<Transaction> _transactions;
  List<Category> _categories;
  Period _currentPeriod;
  Preferences _prefs;

  int _selectedIndex = 0;
  List<String> categoriesFiltered = [];
  bool isAnyCategoryFiltered = false;

  @override
  void initState() {
    super.initState();
    retrieveNewData(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    if (_categories != null) {
      categoriesFiltered = _categories
          .where((cat) => !cat.unfiltered)
          .map((cat) => cat.cid)
          .toList();
      isAnyCategoryFiltered = categoriesFiltered.length > 0;
      _transactions = _transactions
          .where((tx) => !categoriesFiltered.contains(tx.cid))
          .toList();
    }

    final List<Map<String, dynamic>> _pages = [
      {
        'name': 'Records',
        'actions': <Widget>[
          searchButton(),
          filterCategoriesButton(),
        ],
        'body': TransactionsList(
          transactions: _transactions,
          categories: _categories,
          currentPeriod: _currentPeriod,
          refreshList: () => retrieveNewData(widget.user.uid),
        ),
        'addButton': FloatingButton(
          context,
          page: MultiProvider(
            providers: [
              FutureProvider<List<Transaction>>.value(
                  value: DatabaseWrapper(widget.user.uid).getTransactions()),
              FutureProvider<List<Category>>.value(
                  value: DatabaseWrapper(widget.user.uid).getCategories()),
            ],
            child: TransactionForm(getTxOrRecTx: () => Transaction.empty()),
          ),
          callback: () => retrieveNewData(widget.user.uid),
        ),
      },
      {
        'name': 'Statistics',
        'actions': <Widget>[
          filterCategoriesButton(),
        ],
        'body': Statistics(
          allTransactions: _transactions,
          categories: _categories,
          currentPeriod: _currentPeriod,
          prefs: _prefs,
        ),
      }
    ];

    return Scaffold(
      drawer: MainDrawer(user: widget.user, openPage: openPage),
      appBar: AppBar(
        title: Text(_pages[_selectedIndex]['name']),
        actions: _pages[_selectedIndex]['actions'],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: <Widget>[_pages[0]['body'], _pages[1]['body']],
      ),
      floatingActionButton: _pages[_selectedIndex]['addButton'],
      bottomNavigationBar: bottomNavBar(),
    );
  }

  Widget searchButton() {
    return IconButton(
      icon: Icon(CommunityMaterialIcons.magnify),
      onPressed: () => showSearch(
        context: context,
        delegate: SearchService(
          _transactions,
          _categories,
          _currentPeriod,
          _prefs,
          retrieveNewData,
        ),
      ),
    );
  }

  Widget filterCategoriesButton() {
    return IconButton(
      icon: Icon(isAnyCategoryFiltered
          ? CommunityMaterialIcons.filter
          : CommunityMaterialIcons.filter_outline),
      onPressed: () async {
        await showDialog(
          context: context,
          builder: (context) {
            return Filter(
              user: widget.user,
              openPage: openPage,
            );
          },
        );
        retrieveNewData(widget.user.uid);
      },
    );
  }

  Widget bottomNavBar() {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(CommunityMaterialIcons.file_document),
          title: Text('Records'),
        ),
        BottomNavigationBarItem(
          icon: Icon(CommunityMaterialIcons.chart_pie),
          title: Text('Statistics'),
        )
      ],
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (_selectedIndex != index) {
          _pageController.jumpToPage(index);
        }
      },
    );
  }

  void retrieveNewData(String uid) async {
    List<Transaction> transactions;
    List<Category> categories;
    Period period;
    Preferences prefs;
    if (await LocalDBService().getUser(uid) == null) {
      transactions = await FireDBService(uid).getTransactions();
      categories = await FireDBService(uid).getCategories();
      period = await FireDBService(uid).getDefaultPeriod();
      prefs = await FireDBService(uid).getPreferences();
    } else {
      RecurringTransactionsService.checkRecurringTransactions(uid);
      transactions = await DatabaseWrapper(uid).getTransactions();
      categories = await DatabaseWrapper(uid).getCategories();
      period = await DatabaseWrapper(uid).getDefaultPeriod();
      prefs = await DatabaseWrapper(uid).getPreferences();
    }
    setState(() {
      _transactions = transactions;
      _categories = categories;
      _currentPeriod = period;
      _prefs = prefs;
    });
  }

  void openPage(Widget page) async {
    goHome(context);
    await showDialog(
      context: context,
      builder: (context) {
        return page;
      },
    );
    retrieveNewData(widget.user.uid);
  }
}
