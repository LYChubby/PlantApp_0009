import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plantsapp/constanst.dart';
import 'package:plantsapp/screens/details/components/icon_card.dart';
import 'package:plantsapp/screens/details/components/image_and_icons.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Column(children: <Widget>[ImageAndIcons(size: size)]),
    );
  }
}
