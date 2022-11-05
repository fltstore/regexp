// To parse this JSON data, do
//
//     final regExpRuleModel = regExpRuleModelFromJson(jsonString);

import 'dart:convert';

List<RegExpRuleModel> regExpRuleModelFromJson(String str) =>
    List<RegExpRuleModel>.from(
      json.decode(str).map((x) => RegExpRuleModel.fromJson(x)),
    );

String regExpRuleModelToJson(List<RegExpRuleModel> data) => json.encode(
      List<dynamic>.from(data.map((x) => x.toJson()),),
    );

class RegExpRuleModel {
  RegExpRuleModel({
    required this.id,
    required this.title,
    required this.placeholder,
    required this.regular,
  });

  final int id;
  final String title;
  final String placeholder;
  final String regular;

  factory RegExpRuleModel.fromJson(Map<String, dynamic> json) =>
      RegExpRuleModel(
        id: json["id"],
        title: json["title"],
        placeholder: json["placeholder"],
        regular: json["regular"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "placeholder": placeholder,
        "regular": regular,
      };
}
