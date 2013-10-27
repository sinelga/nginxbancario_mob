import 'dart:html';
import 'dart:async';
import 'domains.dart';
import "package:js/js.dart" as js;
import "package:jsonp/jsonp.dart" as jsonp;
import 'events/clickonitemevent.dart' as clickonitemevent;

List<RssFeedItem> rssFeedItemArr;
List<ForMark> forMarkList;
var rssfeeder;

void main() {
  
  forMarkList = new List<ForMark>();
    
  Future<js.Proxy> result = jsonp.fetch(
//      select * from data.html.cssselect where url="www.corriere.it/economia/corriereconomia" and css=".homearticle-box"
//      uri: "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20data.html.cssselect%20where%20url%3D%22www.corriere.it%2Feconomia%2Fcorriereconomia%22%20and%20css%3D%22.homearticle-box%22&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=?"
        uri: "http://146.185.151.26/redis?callback=?"
  
  );
  
  result.then((js.Proxy proxy) {

    var items = proxy;
    
    for (var i=0;i < 12;i++){
      ForMark forMark = new ForMark();
      
      forMark.Cont = items[i]["Cont"];
      forMark.ImageLink = items[i]["ImgLink"];
      forMark.Title = items[i]["Title"];
      forMarkList.add(forMark);

    }
    js.release(proxy);
    
    for (var i=0;i < forMarkList.length;i++){
      
      createMediaObject(i,forMarkList[i]);
      
    }
    
  });
  
  rssfeeder = querySelector("#rssfeeder");
    
}
createMediaObject(i,ForMark item){
  
  var id = i.toString();
  var title ="<i class='fa fa-share fa-2x'></i><div class='googlefonttitle'>"+item.Title+".</div>";
  var pubdate = item.PubDate;
  var imagelink = item.ImageLink;
  var cont = "<p class='media-heading googlefontcont'>"+item.Cont.substring(0, 25)+"...</p>";
  
  var htmlstr = "<div class='media'><img class='media-object pull-left img-thumbnail itemimage' src='${imagelink}' alt=''><div class='media-body'> <h4 class='media-heading'>${title}</h4>${cont}</div></div>";
  
  var divElement = new DivElement();
  divElement.onClick.listen((event) => clickonitemevent.show(event,forMarkList));

  divElement.setInnerHtml(htmlstr, treeSanitizer: new NullTreeSanitizer() );
  divElement.id =id; 
  
  rssfeeder.append(divElement);
 
}
class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(Node node) {}
}