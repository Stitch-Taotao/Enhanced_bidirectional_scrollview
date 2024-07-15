// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:bidirectional_load_scrollview/bidirectional_load_scrollview.dart';
import 'package:flutter/material.dart';



void main() {
  FractionalTranslation;
  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late InfiniteScorllController<int> infiniteScorllController;

  @override
  void initState() {
    super.initState();
    var loadingAutoScrollLoad2 = loadingAutoScrollLoad<int>();
    infiniteScorllController = InfiniteScorllController<int>(
      initList: () {
        return UserInitOperation(showKey: 3, keys: List.generate(20, (index) => index + 1));
      },
      buildItem: (key) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(),
            color: Colors.red,
          ),
          height: 100,
          child: Column(
            children: [
              Container(
                color: Colors.blueAccent,
                key: Tagkey(Tag(category: Category.blue)),
                height: 30,
                child: Center(
                    child: Text(
                  key.dataKey.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                )),
              ),
              const SizedBox(height: 2),
              Expanded(
                  child: Container(
                key: Tagkey(Tag(category: Category.yellow)),
                margin: const EdgeInsets.symmetric(horizontal: 15),
                color: Colors.amber,
              ))
            ],
          ),
        );
      },
      maxCount: 30,
      // loadTrigger: emptyLoad(),
      // loadTrigger: autoScrollLoad(),
      loadTrigger: indicatorLoad(),
      // loadTrigger: loadingAutoScrollLoad2,
    );
    loadingAutoScrollLoad2.headerIndicator?.isProcessingNotifier.addListener(() {
      if (loadingAutoScrollLoad2.headerIndicator?.isProcessingNotifier.value ?? false) {
        // mtLog("isProcessing");
      } else {
        // mtLog("not isProcessing");
      }
    });
  }

  LoadTrigger<T> emptyLoad<T extends Object>() {
    return IndicatorLoadTrigger();
  }

  IndicatorLoadTrigger<T> indicatorLoad<T extends Object>() {
    return IndicatorLoadTrigger<T>(
      appendHeadTask: (infiniteScorllController) {
        final source = infiniteScorllController.source.keyItemMap.keys.toList();
        int count = 5;
        List<int> result = [];

        final first = source.firstOrNull;
        final key = first;
        if (key != null) {
          int newIndex = key.dataKey as int;
          newIndex -= count;
          result = List.generate(count, (index) => newIndex++);
        }

        // return SynchronousFuture(result as List<T>);
        return Future.delayed(const Duration(seconds: 1), () {
          return result as List<T>;
        });
      },
      appendFootTask: (infiniteScorllController) {
        final source = infiniteScorllController.source.keyItemMap.keys.toList();
        int count = 5;
        List<int> result = [];

        final first = source.lastOrNull;
        final key = first;
        if (key != null) {
          int newIndex = key.dataKey as int;
          // newIndex -= count;
          result = List.generate(count, (index) => ++newIndex);
        }

        // return SynchronousFuture(result as List<T>);
        return Future.delayed(const Duration(seconds: 1), () {
          return result as List<T>;
        });
      },
      headerIndicatorBuilder: (status) {
        return ClassicIndicator(indicatorNotifierStatus: status);
      },

      // headerIndicatorBuilder: (manager, controller) {
      //   return ClassicHeaderIndicator(
      //     infiniteScorllController: controller as InfiniteScorllController<T>,
      //     processManager: manager,
      //   );
      // },
    );
  }

  AutoLoadTrigger<T> autoScrollLoad<T extends Object>() {
    return AutoLoadTrigger<T>(
      appendHeadTask: (infiniteScorllController) {
        final source = infiniteScorllController.source.keyItemMap.keys.toList();
        int count = 5;
        List<int> result = [];

        final first = source.firstOrNull;
        final key = first;
        if (key != null) {
          int newIndex = key.dataKey as int;
          newIndex -= count;
          result = List.generate(count, (index) => newIndex++);
        }

        // return SynchronousFuture(result as List<T>);
        return Future.delayed(const Duration(seconds: 2), () {
          return result as List<T>;
        });
      },
      appendFootTask: (infiniteScorllController) {
        final source = infiniteScorllController.source.keyItemMap.keys.toList();
        int count = 5;
        List<int> result = [];

        final first = source.lastOrNull;
        final key = first;
        if (key != null) {
          int newIndex = key.dataKey as int;
          // newIndex -= count;
          result = List.generate(count, (index) => ++newIndex);
        }

        // return SynchronousFuture(result);
        return Future.delayed(const Duration(seconds: 2), () {
          return result as List<T>;
        });
      },
    );
  }

  AutoLoadTrigger<T> loadingAutoScrollLoad<T extends Object>() {
    return AutoLoadTrigger<T>(
      appendHeadTask: (infiniteScorllController) {
        final source = infiniteScorllController.source.keyItemMap.keys.toList();
        int count = 5;
        List<int> result = [];

        final first = source.firstOrNull;
        final key = first;
        if (key != null) {
          int newIndex = key.dataKey as int;
          newIndex -= count;
          result = List.generate(count, (index) => newIndex++);
        }

        // return SynchronousFuture(result as List<T>);
        return Future.delayed(const Duration(seconds: 2), () {
          return result as List<T>;
        });
      },
      appendFootTask: (infiniteScorllController) {
        final source = infiniteScorllController.source.keyItemMap.keys.toList();
        int count = 5;
        List<int> result = [];

        final first = source.lastOrNull;
        final key = first;
        if (key != null) {
          int newIndex = key.dataKey as int;
          // newIndex -= count;
          result = List.generate(count, (index) => ++newIndex);
        }

        // return SynchronousFuture(result);
        return Future.delayed(const Duration(seconds: 2), () {
          return result as List<T>;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget infiniteScrollList = InfiniteScrollList<int>(
      infiniteScorllController: infiniteScorllController,
    );
    // infiniteScrollList = ScrollConfiguration(
    //     behavior: MTScrollBehavior(physics: MTScrollPhysics(infiniteScorllController: infiniteScorllController)), child: infiniteScrollList);
    // infiniteScrollList = EasyRefresh(
    //   controller: easyController,
    //   child: infiniteScrollList,
    //   onRefresh: () {
    //     final task = infiniteScorllController.trickAppendData(
    //         appendLeading: true,
    //         request: () {
    //           final source = infiniteScorllController.source.keyItemMap.keys.toList();
    //           int count = 5;
    //           List<int> result = [];
    //           final first = source.firstOrNull;
    //           final key = first;
    //           if (key != null) {
    //             int newIndex = key.dataKey;
    //             newIndex -= count;
    //             result = List.generate(count, (index) => newIndex++);
    //           }
    //           return Future.delayed(const Duration(seconds: 2), () => result);
    //         });
    //     // if (task != null) {
    //     return task.taskStatus
    //       ..listenComplete(() {
    //         easyController.finishRefresh();
    //       })
    //       ..listenCancel(() {});
    //     // }
    //     // easyController.finishRefresh();
    //   },
    //   onLoad: () {},
    //   simultaneously: true,
    // );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll List'),
      ),
      body: infiniteScrollList,
      floatingActionButton: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          onPressed: () {
            setState(() {});
          },
          child: const Text("直接刷新UI"),
        ),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              print("点击了跳转0，此时keys是:${infiniteScorllController.source.keyItemMap.keys.map((e) => e.dataKey).toList()}");
              if (infiniteScorllController.source.tagKeyMap.keys.contains(0)) {
                infiniteScorllController.jumpExistKey(tag: 0);
              } else {
                infiniteScorllController.jumpNoExistkey(
                    operation: UserReplaceOperation.sync(
                  keys: List.generate(20, (index) => index - 10),
                  showKey: 0,
                ));
              }
            });
          },
          child: const Text("如果有0，直接跳，无则加载再跳"),
        ),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              /// 跳转到第60个  包含有的清空
              if (infiniteScorllController.source.keyItemMap.keys.length >= 10) {
                // final key = infiniteScorllController.source.keyItemMap.keys.elementAt(5);
                final key = infiniteScorllController.source.keyItemMap.keys.first;
                // infiniteScorllController.jump(key: key, tagKey: Tagkey(Tag(category: Category.yellow)));
                // infiniteScorllController.jump(key: key);
                infiniteScorllController.jumpExistKey(
                  tag: key.dataKey,
                  showTag: Tag(category: Category.yellow),
                  releateOffset: 0,
                );
              }
            });
          },
          child: const Text("跳到最前"),
        ),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              /// 跳转到第60个  包含有的清空
              if (infiniteScorllController.source.keyItemMap.keys.length >= 10) {
                // final key = infiniteScorllController.source.keyItemMap.keys.elementAt(5);
                final key = infiniteScorllController.source.keyItemMap.keys.last;
                // infiniteScorllController.jump(key: key, tagKey: Tagkey(Tag(category: Category.yellow)));
                // infiniteScorllController.jump(key: key);
                infiniteScorllController.jumpExistKey(
                  tag: key.dataKey,
                  showTag: Tag(category: Category.yellow),
                  releateOffset: 0,
                );
              }
            });
          },
          child: const Text("跳到最后"),
        ),
      ]),
    );
  }
}

class Category {
  final String name;
  const Category(
    this.name,
  );
  static const Category blue = Category("Blue");
  static const Category yellow = Category("Yellow");

  @override
  bool operator ==(covariant Category other) {
    if (identical(this, other)) return true;

    return other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
