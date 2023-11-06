import 'package:flutter/material.dart';
import 'package:neptune_fob/data/text_style_handler.dart';
import 'package:neptune_fob/ui/image_view.dart';
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:provider/provider.dart';

class OgpDisplay extends StatefulWidget {
  const OgpDisplay({super.key, required this.url});
  final String url;

  @override
  State<OgpDisplay> createState() => OgppWidgetState();
}

class OgppWidgetState extends State<OgpDisplay> {
  OgpData? ogpData;

  void _getOgp() async {
    ogpData = await OgpDataExtract.execute(widget.url);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (ogpData == null) {
      _getOgp();
      return const Text('Loading...');
    }
    // return Text('''\t\t${ogpData?.title ?? 'Loading...'}\n
    //               \t\t${ogpData?.description ?? ''}''');
    final ratio = double.parse(ogpData?.imageHeight ?? "100") / double.parse(ogpData?.imageWidth ?? "100");
    Color none = const Color.fromARGB(0, 0, 0, 0);
    return Column(
      children: [
        Consumer<TextStyleHandler>(
          builder: (context, textStyleHandler, child) => Text(
            '\t\t${ogpData?.siteName ?? 'Loading...'}',
            style: TextStyle(
              fontFamily: textStyleHandler.font,
              fontSize: textStyleHandler.fontSize,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.2 * ratio,
          ),
          child: MaterialButton(
            splashColor: none,
            color: none,
            hoverColor: none,
            onPressed: () => showDialog(
              context: context,
              builder: (BuildContext context) => ImageView(
                image: Image.network(ogpData?.image ?? ''),
              ),
            ),
            child: Image.network(ogpData?.image ?? ''),
          ),
        ),
      ],
    );
  }
}
