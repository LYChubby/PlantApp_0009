import 'package:flutter/material.dart';
import 'package:plantsapp/constanst.dart';
import 'package:plantsapp/screens/home/components/featured_plants.dart';
import 'package:plantsapp/screens/home/components/header_with_searchbox.dart';
import 'package:plantsapp/screens/home/components/recomends_plants.dart';
import 'package:plantsapp/screens/home/components/title_with_more_btn.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          HeaderWithSearchBox(size: size),
          TitleWithMoreBtn(title: "Recommended", press: () {}),
          RecomendsPlants(),
          TitleWithMoreBtn(title: "Featured Plants", press: () {}),
          FeaturedPlants(),
          SizedBox(height: kDefaultPadding),
        ],
      ),
    );
  }
}
