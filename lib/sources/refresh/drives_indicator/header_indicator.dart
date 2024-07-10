import 'builder_indicator.dart';

class HeaderIndicator<T extends Object> extends BuilderIndicator<T> {
  HeaderIndicator({
    required super.processManager,
    super.builder,
    required super.loadTrigger,
  });

  @override
  bool get isHeader => true;
}
