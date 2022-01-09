<?
  $Page["Items"] = $Items["Items"];
  cortege_push($Page["HTML"],"<Form>\n".implode("\n",$Items["HTML"])."\n</Form>\n");
?>