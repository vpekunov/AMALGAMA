<?php
$EXPORT = GetNextMail("EXPORT");
if ($EXPORT === "") {
   global $XML;
   $ref = $XML->match("/System/Elements/Element[@ClassID='clsE_Export']/Parameters/Parameter[@ID='Lang']/text()");
   if ($ref[0] != "") {
       $EXPORT = $XML->wholeText($ref[0]);
   }
}
if ($EXPORT !== "") {
   SwitchExportOn();
   if ($Stage == stCall) {
     if ($EXPORT == "Russian") {
?> Пусть функция <?php echo $this->ID; ?> определена на стенке "<?php echo $this->Bound; ?>".<?php
     } else if ($EXPORT == "XML") {
       $n = GetNextMail("COUNTER");
       ExportXMLElement($n++, "clsE_SFun_IsBound", "ID$n", array("Name"=>$this->ID, "Bound"=>$this->Bound));
       PutMail("COUNTER", $n);
     }
   } else if ($Stage == stResource && $EXPORT == "XML") {
      $n = GetNextMail("OBJS");
      $n++;
      PutMail("OBJS", $n);
   }
   PutMail("EXPORT",$EXPORT);
   return;
}

cortege_push($Val["Boundary"],$this->Bound);
?>
