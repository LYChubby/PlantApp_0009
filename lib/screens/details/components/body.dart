import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plantsapp/constanst.dart';
import 'package:plantsapp/screens/details/components/icon_card.dart';
import 'package:plantsapp/screens/details/components/image_and_icons.dart';
import 'package:plantsapp/screens/details/components/title_and_price.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          ImageAndIcons(size: size),
          TitleAndPrice(title: "Angelica", country: "Russia", price: 440),
          SizedBox(height: kDefaultPadding),
          Row(
            children: <Widget>[
              SizedBox(
                width: size.width / 2,
                height: 84,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    "Buy Now",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: size.width / 2,
                  height: 84,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: kBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      "Description",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: kDefaultPadding * 2),
        ],
      ),
    );
  }
}
