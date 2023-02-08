<?php
$this->Expression = trim($this->Expression);

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
?> Введем константу <?php echo $this->ID; ?>, возвращающую выражение "<?php echo trim($this->Expression); ?>".<?php
     } else if ($EXPORT == "XML") {
       $n = GetNextMail("COUNTER");
       ExportXMLElement($n++, "clsE_SConst", "ID$n", array("Name"=>$this->ID, "Expression"=>trim($this->Expression)));
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

$this->Expression = UnrollIfNotExport($this->Expression);

if ($this->Expression[0]=="@")
   {
    cortege_push($Val["FText"],strtok(substr($this->Expression,1),"{"));
    cortege_push($Val["Parameters"],substr($this->Expression,1));
   }
else
   cortege_push($Val["FText"],$this->Expression);
?>
