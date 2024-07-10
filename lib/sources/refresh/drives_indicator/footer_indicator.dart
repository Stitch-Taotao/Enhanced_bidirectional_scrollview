import 'builder_indicator.dart';

class FooterIndicator<T extends Object> extends BuilderIndicator<T> {
  FooterIndicator({
    required super.processManager,
    super.builder,
    required super.loadTrigger,
  });

  @override
  bool get isHeader => false;
}
