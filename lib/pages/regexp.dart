import 'package:bot_toast/bot_toast.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:http/http.dart' as http;
import 'package:regexp/models/rule.dart';
import 'package:regexp/types/index.dart';

import '../extensions/index.dart';
import '../types/alias.dart';

const kRuleRemoteUrl =
    'https://gitee.com/mirrors/any-rule/raw/master/packages/www/src/RULES.js';

typedef ListRule = L<RegExpRuleModel>;

enum KMenuType {
  local,
  remote,
}

class RegexpPage extends StatefulWidget {
  const RegexpPage({Key? key}) : super(key: key);

  @override
  State<RegexpPage> createState() => _RegexpPageState();
}

class _RegexpPageState extends State<RegexpPage> {
  bool isLoading = false;
  ListRule _assetsData = [];
  ListRule _remoteData = [];

  ListRule get data {
    if (_menuType == KMenuType.local) {
      return _assetsData;
    }
    return _remoteData;
  }

  GenCodeType genCodeType = GenCodeType.js;
  bool showOptions = false;

  KMenuType _menuType = KMenuType.local;
  KMenuType get menuType => _menuType;
  set menuType(KMenuType type) {
    _menuType = type;
    setState(() {});
    if (_menuType == KMenuType.remote && _remoteData.isEmpty) {
      isLoading = true;
      setState(() {});
      asyncLoadRemoteRule();
    } else {
      bindRuleController(type);
    }
  }

  bindRuleController(KMenuType type, {bool beforeClear = true}) {
    if (beforeClear) {
      ruleController.clear();
    }
    var data = type == KMenuType.local ? _assetsData : _remoteData;
    for (var element in data) {
      ruleController[element.title] = TextEditingController();
    }
  }

  List<Map<String, dynamic>> menus = [
    {
      "id": KMenuType.local,
      "icon": Icons.cloud_off_outlined,
      "title": "本地",
    },
    {
      "id": KMenuType.remote,
      "icon": Icons.cloud,
      "title": "云端",
    },
  ];

  FlutterQjs? engine;

  beforeHook() async {
    asyncLoadMemRule();
  }

  asyncLoadRemoteRule() async {
    _remoteData = await fetchRemoteRuleAndParse();
    setState(() {});
    bindRuleController(KMenuType.remote, beforeClear: true);
  }

  asyncLoadMemRule() async {
    _assetsData = await loadRule();
    setState(() {});
    for (var element in _assetsData) {
      ruleController[element.title] = TextEditingController();
    }
  }

  Map<String, TextEditingController> ruleController = {};
  Map<String, bool> ruleInstanceNeedClearMap = {};

  P<ListRule> loadRule() async {
    var data = await rootBundle.loadString('assets/ruler.json');
    return regExpRuleModelFromJson(data);
  }

  handleTapVerify(RegExpRuleModel e) {
    TextEditingController? controller = ruleController[e.title];
    if (controller == null) {
      sayFillContent();
      return;
    }
    String text = controller.text;
    if (text.isEmpty) {
      sayFillContent();
      return;
    }
    RegExp regExp = RegExp(e.regular);
    bool find = regExp.hasMatch(text);
    String msg = '检验${find ? "成功" : "失败"}';
    BotToast.showText(text: msg);
  }

  sayFillContent() {
    BotToast.showText(text: '请输入内容');
  }

  String easyGenCodeWithString(String input, GenCodeType codeType) {
    switch (codeType) {
      case GenCodeType.js:
        return '/$input/';
      case GenCodeType.dart:
        return 'RegExp(r"$input")';
      default:
        return input;
    }
  }

  handleTapCopy(RegExpRuleModel e) async {
    String result = e.regular;
    String data = easyGenCodeWithString(result, genCodeType);
    await FlutterClipboard.copy(data);
    BotToast.showText(text: '复制到剪贴板成功');
  }

  P<String> fetchRuleAnyWithRemote() async {
    http.Response response =
        await http.get(Uri.parse(kRuleRemoteUrl), headers: {
      "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
          "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36",
    });
    return response.body;
  }

  P<ListRule> fetchRemoteRuleAndParse({loadingDone = true}) async {
    ListRule result = [];
    try {
      String data = await fetchRuleAnyWithRemote();
      data = data.replaceFirst("module.exports =", "const data =");
      engine = FlutterQjs(
        stackSize: 1024 * 1024,
      );
      engine?.evaluate(data);
      engine?.evaluate('''
        const result = data.map(function(item){
          const rule = item['rule'].toString()
          return {
            ...item,
            rule
          }
        })
      ''');
      L<dynamic> rules = engine?.evaluate('result');
      for (var model in rules) {
        Map map = Map.from(model);
        String title = map['title'];
        String rule = map['rule'];
        rule = rule.substring(1);

        // 全局模式
        bool matchGlobal = rule[rule.length - 1] == 'g';
        int stepOffset = matchGlobal ? 2 : 1;
        rule = rule.substring(0, rule.length - stepOffset);

        L<String> examples = List.from(map['examples']).map((e) {
          return e.toString();
        }).toList();
        String placeholder = '例如: ';
        placeholder += examples.join(", ");
        result.add(RegExpRuleModel(
          id: 1,
          title: title,
          placeholder: placeholder,
          regular: rule,
        ));
      }
      engine?.port.close();
      engine?.close();
      engine = null;
      if (loadingDone) {
        isLoading = false;
        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    beforeHook();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(42),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Row(
            mainAxisAlignment: !showOptions
                ? MainAxisAlignment.end
                : MainAxisAlignment.spaceBetween,
            children: [
              if (showOptions)
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("复制到剪贴板格式"),
                      const SizedBox(width: 6.0),
                      Row(
                        children: GenCodeType.values
                            .map(
                              (e) => Row(
                                children: [
                                  const SizedBox(width: 4.2),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        genCodeType = e;
                                        setState(() {});
                                      },
                                      child: Builder(builder: (context) {
                                        var isCurr = genCodeType == e;
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isCurr
                                                ? Colors.blue
                                                : Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(4.2),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 1.2,
                                          ),
                                          child: Text(
                                            e.name.capitalizeFirstLetter(),
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: isCurr
                                                  ? Colors.white
                                                  : Colors.blue,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: menus
                    .map(
                      (e) => TextButton(
                        onPressed: () {
                          menuType = e['id'];
                          setState(() {});
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              e['icon'],
                              color: menuType == e['id']
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4.2),
                            Text(
                              e['title'],
                              style: TextStyle(
                                color: menuType == e['id']
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              IconButton(
                onPressed: () {
                  showOptions = !showOptions;
                  setState(() {});
                },
                icon: const Icon(
                  Icons.format_list_bulleted,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
      body: CupertinoScrollbar(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
            ),
            child: Builder(builder: (context) {
              if (menuType == KMenuType.remote && isLoading) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return Column(
                children: data
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
                                  hintText: e.placeholder,
                                  suffixIcon: Builder(builder: (context) {
                                    bool needClear =
                                        ruleInstanceNeedClearMap[e.title] ??
                                            false;
                                    if (!needClear) {
                                      return const SizedBox.shrink();
                                    }
                                    return MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () {
                                          ruleController[e.title]?.clear();
                                          ruleInstanceNeedClearMap[e.title] =
                                              false;
                                          setState(() {});
                                        },
                                        child: const Icon(
                                          CupertinoIcons.clear,
                                          size: 14,
                                        ),
                                      ),
                                    );
                                  }),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4.2),
                                  ),
                                ),
                                onChanged: (value) {
                                  ruleInstanceNeedClearMap[e.title] =
                                      value.isNotEmpty;
                                  setState(() {});
                                },
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
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
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
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.fingerprint,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                              Text("点击验证"),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color:
                                            const Color.fromRGBO(28, 28, 30, 1),
                                        borderRadius:
                                            BorderRadius.circular(2.4),
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
                                    const SizedBox(width: 6.0),
                                    GestureDetector(
                                      onTap: () => handleTapCopy(e),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromRGBO(
                                                142, 142, 147, 1),
                                            borderRadius:
                                                BorderRadius.circular(4.2),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4.2,
                                          ),
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.content_copy_sharp,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              Text("点击复制"),
                                            ],
                                          ),
                                        ),
                                      ),
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
              );
            }),
          ),
        ),
      ),
    );
  }
}
