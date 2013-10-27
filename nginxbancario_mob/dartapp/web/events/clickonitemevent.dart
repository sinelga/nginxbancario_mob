import '../domains.dart';
import 'dart:html';
import 'closeevent.dart' as closeevent;

var start = false;
var close = DivElement;
//var seleteditemplace;

show(event,List<ForMark> forMarkList) {

  if (!start) {
    
    close = new Element.html("<i class='fa fa-times-circle-o fa-2x'></i>");
    close.onClick.listen((event) => closeevent.close(event));
    var closeelem = querySelector('#close');
    closeelem.append(close);

    start=true;
  } else {
    
    querySelector('#close').hidden = false;
    
  }
  
  var seleteditemplace = querySelector("#seleteditem");
  querySelector("#rssfeeder").hidden=true;
  var itemid = int.parse(event.currentTarget.id);
  var item = forMarkList[itemid];

  var title ="<i class='fa fa-quote-left'></i><div class='googlefonttitle'>"+item.Title +".</d>&nbsp;<i class='fa fa-quote-right'></i>";
  var pubdate = item.PubDate;
  var imagelink = item.ImageLink;
  var cont;
  if (item.Cont.length > 500) {
    cont = item.Cont.substring(0, 500)+"...";
  
  } else {
    cont = item.Cont;
    
  }
  
//  var htmlstr="<div class='jumbotron'><div class='container'> ${title}<div class='media'><img class='media-object pull-left itemimage' src='${imagelink}' alt=''><div class='media-body'> <p class='media-heading'>${cont}</p></div></div> </div></div>";
  var htmlstr="<div class='page-header'> ${title}</div><div class='media'><img class='media-object img-thumbnail itemimage' src='${imagelink}' alt=''><div class='media-body'> <p class='media-heading googlefontcont'>${cont}</p></div></div> ";
  
  var divElement = new DivElement();
  divElement.setInnerHtml(htmlstr, treeSanitizer: new NullTreeSanitizer() );
  
  if (seleteditemplace.hasChildNodes()) {
//  seleteditemplace.append(divElement);
//    print("replace");
    seleteditemplace.children.clear();
    seleteditemplace.append(divElement);
  } else {
//    print("append");
    seleteditemplace.append(divElement);
  }
  
}

class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(Node node) {}
}