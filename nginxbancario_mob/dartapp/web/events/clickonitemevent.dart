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
//  var ads = "<script async src='//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'></script><ins class='adsbygoogle' style='display:inline-block;width:200px;height:200px' data-ad-client='ca-pub-4265026941264081' data-ad-slot='6705877857'></ins> <script> (adsbygoogle = window.adsbygoogle || []).push({}); </script>";
  var ads = "<script async src='//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'></script><ins class='adsbygoogle' style='display:inline-block;width:180px;height:150px' data-ad-client='ca-pub-4265026941264081' data-ad-slot='9659344258'></ins> <script> (adsbygoogle = window.adsbygoogle || []).push({}); </script>";
  
  var htmlstr="<div class='page-header'> ${title}</div><div class='media'><div class='pull-right'>${ads}</div><img class='media-object img-thumbnail itemimage' src='${imagelink}' alt=''><div class='media-body'><p class='media-heading googlefontcont'>${cont}</p></div></div> ";
  
  var divElement = new DivElement();
  divElement.setInnerHtml(htmlstr, treeSanitizer: new NullTreeSanitizer() );
  
  if (seleteditemplace.hasChildNodes()) {

    seleteditemplace.children.clear();
    seleteditemplace.append(divElement);
  } else {

    seleteditemplace.append(divElement);
  }
  
}

class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(Node node) {}
}