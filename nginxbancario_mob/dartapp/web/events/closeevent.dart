import 'dart:html';


close(event){
 
//  querySelector("#rssfeeder").hidden=false;
  querySelector("#rssfeeder").style.display="block";
//  querySelector('#close').hidden=true;
  querySelector('#close').style.display="none";
  var seleteditemplace = querySelector("#seleteditem");
  if (seleteditemplace.hasChildNodes()) {
    
    seleteditemplace.children.clear();
  }
  
}