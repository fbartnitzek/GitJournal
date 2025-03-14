import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:gitjournal/note.dart';
import 'package:gitjournal/utils.dart';
import 'package:gitjournal/apis/git.dart';
import 'package:gitjournal/screens/note_editor.dart';
import 'package:gitjournal/screens/note_viewer.dart';
import 'package:gitjournal/state_container.dart';
import 'package:gitjournal/widgets/app_drawer.dart';
import 'package:gitjournal/widgets/journal_list.dart';

class HomeScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final container = StateContainer.of(context);
    final appState = container.appState;

    var createButton = FloatingActionButton(
      key: const ValueKey("FAB"),
      onPressed: () => _newPost(context),
      child: Icon(Icons.add),
    );

    Widget journalList = JournalList(
      notes: appState.notes,
      noteSelectedFunction: (noteIndex) {
        var route = MaterialPageRoute(
          builder: (context) => NoteBrowsingScreen(
            notes: appState.notes,
            noteIndex: noteIndex,
          ),
        );
        Navigator.of(context).push(route);
      },
      emptyText: "Why not add your first\n Journal Entry?",
    );

    bool shouldShowBadge =
        !appState.remoteGitRepoConfigured && appState.hasJournalEntries;
    var appBarMenuButton = BadgeIconButton(
      key: const ValueKey("DrawerButton"),
      icon: const Icon(Icons.menu),
      itemCount: shouldShowBadge ? 1 : 0,
      onPressed: () {
        _scaffoldKey.currentState.openDrawer();
      },
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('GitJournal'),
        leading: appBarMenuButton,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NoteSearch(),
              );
            },
          )
        ],
      ),
      floatingActionButton: createButton,
      body: Center(
        child: RefreshIndicator(
            child: journalList,
            onRefresh: () async {
              try {
                await container.syncNotes();
              } on GitException catch (exp) {
                showSnackbar(context, exp.cause);
              }
            }),
      ),
      drawer: AppDrawer(),
    );
  }

  void _newPost(BuildContext context) {
    var route = MaterialPageRoute(builder: (context) => NoteEditor());
    Navigator.of(context).push(route);
  }
}

class NoteSearch extends SearchDelegate<Note> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildJournalList(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildJournalList(context, query);
  }

  JournalList buildJournalList(BuildContext context, String query) {
    final container = StateContainer.of(context);
    final appState = container.appState;

    // TODO: This should be made far more efficient
    var q = query.toLowerCase();
    var filteredNotes = appState.notes.where((note) {
      return note.body.toLowerCase().contains(q);
    }).toList();

    Widget journalList = JournalList(
      notes: filteredNotes,
      noteSelectedFunction: (noteIndex) {
        var route = MaterialPageRoute(
          builder: (context) => NoteBrowsingScreen(
            notes: filteredNotes,
            noteIndex: noteIndex,
          ),
        );
        Navigator.of(context).push(route);
      },
      emptyText: "No Search Results Found",
    );
    return journalList;
  }
}
