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
?> Введем вещество <?php echo $this->ID; ?> с обозначением "<?php echo $this->Substance; ?>" на фазе <?php echo $Phase["_ID"][0]; ?>.<?php
     } else if ($EXPORT == "XML") {
       $n = GetNextMail("COUNTER");
       ExportXMLElement($n++, "clsE_SSubstance", "ID$n", array("Name"=>$this->ID, "Substance"=>$this->Substance, "Phase"=>$Phase["_ID"][0]));
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

$Calc["Parameters"] = $Phase["Parameters"];
cortege_push($Calc["Phase"],$Phase["Phase"][0]);
cortege_push($Calc["DefPhase"],$Phase["_ID"][0]);
$Calc["Nc"] = $Phase["Nc"];

cortege_push($Calc["Name"],$this->ID);

if ($Phase["Nc"][0]>1 || !$Phase["Phase"][0]["Carrier"])
   MakeError("Model Error","Substance can be defined on carrier single phase only",__LINE__);

cortege_push($Calc["Substance"],$this->Substance);
cortege_push($Val["Name"],$this->ID);
cortege_push($Val["FText"],$this->ID);
$Val["Nc"] = $Phase["Nc"];
?>
