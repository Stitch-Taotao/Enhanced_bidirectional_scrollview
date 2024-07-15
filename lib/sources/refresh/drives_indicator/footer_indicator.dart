import '../indicator_widgets/classic_indicator.dart';
import 'builder_indicator.dart';

class FooterIndicator<T extends Object> extends BuilderIndicator<T> {
  FooterIndicator({
    required super.processManager,
    super.builder,
    required super.infiniteScorllController,
  });
  @override
  IndicatorBuilder get defaultBuilder => (notifier) {
        return ClassicIndicator(indicatorNotifierStatus: notifier);
      };
  @override
  bool get isHeader => false;
}
