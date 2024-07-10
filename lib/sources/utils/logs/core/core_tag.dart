///MARK - This requires the 'class-modifiers' language feature to be enabled.
///Try updating your pubspec.yaml to set the minimum SDK constraint to 3.0.0 or higher, and running 'pub get'
// abstract mixin class AbsMixinTagsConfig {
abstract mixin class AbsMixinConfig {
  // ignore: non_constant_identifier_names, constant_identifier_names
  static const String _TagNull = "null";
  final String tagNull = _TagNull;
  String get defaultTag;
  List<Object> get showLogTags;
  bool get enable;
}

abstract class BaseConfig with AbsMixinConfig {
  bool get includeDefautTag => true;
  @override
  String get defaultTag => tagNull;

  @override
  List<String> get showLogTags => [if (includeDefautTag) defaultTag, ...tags];

  /// 自己添加Tags
  List<String> get tags;
  @override
  bool get enable => true;
}
