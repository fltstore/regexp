// ignore_for_file: avoid_unnecessary_containers

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:regexp/models/rule.dart';

import '../types/alias.dart';

typedef ListRule = L<RegExpRuleModel>;

class RegexpPage extends StatefulWidget {
  const RegexpPage({Key? key}) : super(key: key);

  @override
  State<RegexpPage> createState() => _RegexpPageState();
}

class _RegexpPageState extends State<RegexpPage> {
  ListRule _data = [];
  beforeHook() async {
    asyncLoadRule();
  }

  asyncLoadRule() async {
    _data = await loadRule();
    setState(() {});
    for (var element in _data) {
      ruleController[element.title] = TextEditingController();
    }
  }

  Map<String, TextEditingController> ruleController = {};

  P<ListRule> loadRule() async {
    var data = await rootBundle.loadString('assets/ruler.json');
    return regExpRuleModelFromJson(data);
  }

  handleTapVerify(RegExpRuleModel e) {
    TextEditingController? controller = ruleController[e.title];
    if (controller == null) return;
    String text = controller.text;
    if (text.isEmpty) return;
    RegExp regExp = RegExp(e.regular);
    bool find = regExp.hasMatch(text);
    String msg = '检验${find ? "成功" : "失败"}';
    BotToast.showText(text: msg);
  }

  @override
  void initState() {
    super.initState();
    beforeHook();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoScrollbar(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
            ),
            child: Column(
              children: _data
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title),
                          const SizedBox(
                            height: 6.0,
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: TextField(
                              controller: ruleController[e.title],
                              style: const TextStyle(
                                fontSize: 12.0,
                              ),
                              maxLines: 1,
                              textAlignVertical: TextAlignVertical.center,
                              textAlign: TextAlign.left,
                              decoration: InputDecoration(
                                suffixIcon: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      ruleController[e.title]?.clear();
                                    },
                                    child: const Icon(
                                      CupertinoIcons.clear,
                                      size: 14,
                                    ),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 6.0,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: DefaultTextStyle(
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      handleTapVerify(e);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            103, 206, 103, 1),
                                        borderRadius:
                                            BorderRadius.circular(4.2),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4.2,
                                      ),
                                      child: const Text("点击验证"),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 4.2,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                          const Color.fromRGBO(28, 28, 30, 1),
                                      borderRadius: BorderRadius.circular(2.4),
                                    ),
                                    constraints: const BoxConstraints(
                                      maxWidth: 240,
                                    ),
                                    child: Text(
                                      e.regular,
                                      maxLines: 10,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    child: const SizedBox(
                                      width: 4.2,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                          142, 142, 147, 1),
                                      borderRadius: BorderRadius.circular(4.2),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4.2,
                                    ),
                                    child: const Text("点击复制"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          const Divider(),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
