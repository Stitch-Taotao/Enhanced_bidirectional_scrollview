import 'package:flutter/material.dart';

class MTRowItem extends StatelessWidget {
  const MTRowItem({
    Key? key,
    required this.child,
    this.borderWidth = 1.0,
    this.borderColor = const Color.fromRGBO(58, 66, 142, 1),
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.decorationColor = Colors.white,
    this.margin = const EdgeInsets.all(8.0)
  }) : super(key: key);
  final Widget child;
  final double borderWidth;
  final Color borderColor;
  final BorderRadius borderRadius;
  final Color decorationColor;
  final EdgeInsets margin;
  @override
  Widget build(BuildContext context) {
    return useContinuousRectangleBorder();
  }

  Widget useContinuousRectangleBorder() {
    return Padding(
      padding:margin ,
      // padding:EdgeInsets.all(0) ,
      child: Container(
        clipBehavior: Clip.antiAlias,
        // padding: const EdgeInsets.all(0),
        decoration: ShapeDecoration(
          //背景
          color: decorationColor,
          //设置四周边框
          shape: ContinuousRectangleBorder(
            side: BorderSide(width: borderWidth, color: borderColor),
            borderRadius: borderRadius,
            // border:  Border.all(width: 1, color: Colors.black),
          ),
          
          //  BoxDecoration(border: Border.all(width: 1,color: Colors.black),borderRadius:BorderRadius.all(Radius.circular(4.0)) ),
        ),
        child: child,
      ),
    );
  }
}
