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
?> Для переменной <?php echo $Calc["_ID"][0]; ?> зададим прямую схему решения.<?php
      for ($i = 0; $i < $powK; $i++) {
          ?> Присоединим правую функцию <?php echo $K["_ID"][$i]; ?> к уравнению переменной <?php echo $Calc["_ID"][0]; ?>.<?php
      }
      for ($i = 0; $i < $powBound; $i++) {
          ?> Присоединим граничную функцию <?php echo $Bound["_ID"][$i]; ?> к уравнению переменной <?php echo $Calc["_ID"][0]; ?>.<?php
      }
    } else if ($EXPORT == "XML") {
      $n = GetNextMail("COUNTER");
      ExportXMLElement($n++, "clsE_SDirectEquation", "ID$n", array("Var"=>$Calc["_ID"][0], "Handler"=>$this->Handler));
      for ($i = 0; $i < $powK; $i++) {
          ExportXMLElement($n++, "clsE_SAddFunction", "ID$n", array("Type"=>"Right", "Fun"=>$K["_ID"][$i], "Var"=>$Calc["_ID"][0]));
      }
      for ($i = 0; $i < $powBound; $i++) {
          ExportXMLElement($n++, "clsE_SAddFunction", "ID$n", array("Type"=>"Bound", "Fun"=>$Bound["_ID"][$i], "Var"=>$Calc["_ID"][0]));
      }
      PutMail("COUNTER", $n);
    }
   } else if ($Stage == stResource && $EXPORT == "XML") {
      $n = GetNextMail("OBJS");
      $n += 1 + $powK + $powBound;
      PutMail("OBJS", $n);
   }
   PutMail("EXPORT",$EXPORT);
   return;
}

$P = "0.0"; HandleParameter($Stage,$P,$Calc["Nc"][0],$Kappa,$Solver["Parameters"],"Kappa".$Calc["Name"][0]);
$P = "0.0"; HandleParameter($Stage,$P,$Calc["Nc"][0],$NuMol,$Solver["Parameters"],"NuMol".$Calc["Name"][0]);
if ($Calc["Nc"][0]>1)
   for ($i=0; $i<$Calc["Nc"][0]; $i++)
       {
        cortege_push($Solver["Kappa"],$Kappa[0]."[".$i."]");
        cortege_push($Solver["NuMol"],$NuMol[0]."[".$i."]");
        cortege_push($Solver["NeedS"],0);
       }
else
   {
    $Solver["Kappa"] = $Kappa;
    $Solver["NuMol"] = $NuMol;
    cortege_push($Solver["NeedS"],0);
   }
?>
