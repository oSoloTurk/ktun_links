import 'package:KTUN/models/website.dart';
import 'package:KTUN/screens/webview.dart';
import 'package:KTUN/utils/UIHelper.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

// ignore: must_be_immutable
class News extends StatefulWidget {
  GlobalKey<NavigatorState> navKey;
  News(this.navKey);

  @override
  _NewsState createState() => _NewsState(navKey);
}

class _NewsState extends State<News> {
  var document;
  List<Website> news = List<Website>();
  GlobalKey<NavigatorState> navKey;
  _NewsState(this.navKey);
  bool loading = true;
  String connectionProtocol = "https";

  @override
  void initState() {
    http
        .read('$connectionProtocol://ktun.edu.tr/tr/Universite/TumDuyurular')
        .then((value) {
      document = parse(value);
      readDocument();
      setState(() {
        loading = false;
      });
    });
    if (document == null) {
      connectionProtocol = "http";
      http
          .read('$connectionProtocol://ktun.edu.tr/tr/Universite/TumDuyurular')
          .then((value) {
        document = parse(value);
        readDocument();
        setState(() {
          loading = false;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? _buildLoadingBar
        : Column(children: <Widget>[
            Expanded(
                child: ListView.builder(
                    itemCount: news.length,
                    itemBuilder: (context, index) {
                      return _createShortcut(news[index]);
                    }))
          ]);
  }

  Widget _createShortcut(Website website) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
            color: UIHelper.colorCard,
            border: Border.all(color: UIHelper.colorBorder)),
        child: Column(
          children: [
            ListTile(
              leading: Icon(website.isWebsite ? Icons.link : Icons.textsms,
                  color: Colors.white),
              title: Text(
                  website.isWebsite ? website.name : website.name.substring(1),
                  style: UIHelper.textTitle),
              subtitle: Text(website.isOpenable ? website.url : website.desc,
                  style: UIHelper.textSubtitle),
            ),
            if (website.isOpenable)
              Text(website.desc,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center),
            if (website.isOpenable)
              ButtonBar(
                alignment: MainAxisAlignment.start,
                children: [
                  FlatButton(
                    textColor: UIHelper.colorPaleText,
                    onPressed: () {
                      Navigator.push(
                          navKey.currentState.overlay.context,
                          MaterialPageRoute(
                              builder: (context) => WebViewContainer(website)));
                    },
                    child: const Text('Uygulamada Aç'),
                  ),
                  if (website.isOpenable)
                    FlatButton(
                      textColor: UIHelper.colorPaleText,
                      onPressed: () {
                        _launchBrowser(website.url);
                      },
                      child: const Text('Tarayıcıda Aç'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  //Launch url
  void _launchBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Widget get _buildLoadingBar => SafeArea(
          child: Column(children: [
        Image.asset("assets/images/launcher_icon.png"),
        Image.asset("assets/images/loading.gif")
      ]));

  void readDocument() {
    http
        .read('$connectionProtocol://ktun.edu.tr/tr/Universite/TumHaberler')
        .then((contents) {
      var document = parse(contents);
      var labCells = document
          .getElementsByTagName('table')[0]
          .getElementsByTagName('tbody')[0]
          .getElementsByTagName('tr');
      news.clear();
      for (int i = 0; i < labCells.length; i++) {
        news.add(Website(
            labCells[i].getElementsByTagName("td")[0].innerHtml,
            "$connectionProtocol://ktun.edu.tr" +
                labCells[i]
                    .getElementsByTagName("td")[2]
                    .getElementsByTagName("a")[0]
                    .attributes["href"],
            labCells[i].getElementsByTagName("td")[1].innerHtml,
            true,
            true));
      }
      setState(() {
        loading = false;
      });
    });
  }
}
