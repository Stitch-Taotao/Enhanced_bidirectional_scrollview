// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

import 'mt_row_item.dart';

class SimpleListModel {
  String? title;
  Map<String, Widget> map;
  SimpleListModel({
    this.title,
    required this.map,
  });
}

class SimpleListPage extends StatefulWidget {
  const SimpleListPage({Key? key, required this.model}) : super(key: key);
  final SimpleListModel model;

  @override
  _SimpleListPageState createState() => _SimpleListPageState();
}

class _SimpleListPageState extends State<SimpleListPage> {
  _SimpleListPageState() : super();
  List<String> get keylist {
    return widget.model.map.keys.toList();
  }

  List<Widget> get pageList {
    return widget.model.map.values.toList();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.model.title != null
          ? AppBar(
              title: Text(widget.model.title!),
            )
          : AppBar(),
      body: ListView.builder(itemCount: keylist.length, itemBuilder: itemBuilder),
    );
  }

  Widget itemBuilder(BuildContext ctx, int index) {
    final String title = keylist[index];
    return MTRowItem(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final f = MaterialPageRoute(builder: (context) {
            return pageList[index];
          });
          Navigator.of(context).push(f);
        },
        child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      softWrap: true,
                    ),
                  ),
                  const Icon(Icons.arrow_right),
                ],
              ),
            )),
      ),
    );
  }
}
