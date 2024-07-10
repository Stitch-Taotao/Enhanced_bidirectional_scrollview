// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

class ClampGravitySimulation extends Simulation {
  ClampGravitySimulation(
    double acceleration,
    double distance,
    double endDistance,
    double velocity,
  )   : _a = acceleration,
        _x = distance,
        _v = velocity,
        _end = endDistance {
    assert(() {
      if ((_end - distance) < 0 && _a > 0) {
        return false;
      } else if ((_end - distance) > 0 && _a < 0) {
        return false;
      }
      return true;
    }(), "");
  }

  final double _x;
  final double _v;
  final double _a;
  final double _end;

  double _normalX(double time) {
    final s = _x + _v * time + 0.5 * _a * time * time;
    print("s:$s v:_$_v");
    return s;
  }

  @override
  double x(double time) => isDone(time) ? _end : _normalX(time);

  @override
  double dx(double time) => _v + time * _a;

  @override
  bool isDone(double time) => _a > 0 ? _normalX(time) >= _end : _normalX(time) <= _end;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'GravitySimulation')}(g: ${_a.toStringAsFixed(1)}, x₀: ${_x.toStringAsFixed(1)}, dx₀: ${_v.toStringAsFixed(1)}, xₘₐₓ: ±${_end.toStringAsFixed(1)})';
}
