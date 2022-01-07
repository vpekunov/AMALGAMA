<?
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
       $Kind = array("clsE_WhirlEquation"=>"вихревой", "clsE_DynEquation"=>"параболический", "clsE_PoissonEquation"=>"пуассоновский", "clsE_SolarEquation"=>"солнечный");
?> Для переменной <? echo $Calc["_ID"][0]; ?> с вязкостью "<? echo $this->NuMol; ?>" и каппой "<? echo $this->Kappa; ?>" зададим <? echo $Kind[$this->ClassID]; ?> решатель.<?
      for ($i = 0; $i < $powK; $i++) {
          ?> Присоединим правую функцию <? echo $K["_ID"][$i]; ?> к уравнению переменной <? echo $Calc["_ID"][0]; ?>.<?
      }
      for ($i = 0; $i < $powS; $i++) {
          ?> Присоединим базовую функцию <? echo $S["_ID"][$i]; ?> к уравнению переменной <? echo $Calc["_ID"][0]; ?>.<?
      }
      for ($i = 0; $i < $powBound; $i++) {
          ?> Присоединим граничную функцию <? echo $Bound["_ID"][$i]; ?> к уравнению переменной <? echo $Calc["_ID"][0]; ?>.<?
      }
    } else if ($EXPORT == "XML") {
      $n = GetNextMail("COUNTER");
      $class = $this->ClassID == "clsE_WhirlEquation" ? "clsE_SWhirlEquation" : "clsE_SEquation";
      ExportXMLElement($n++, $class, "ID$n", array("Var"=>$Calc["_ID"][0], "Handler"=>$this->Handler, "NuMol"=>$this->NuMol, "Kappa"=>$this->Kappa));
      for ($i = 0; $i < $powK; $i++) {
          ExportXMLElement($n++, "clsE_SAddFunction", "ID$n", array("Type"=>"Right", "Fun"=>$K["_ID"][$i], "Var"=>$Calc["_ID"][0]));
      }
      for ($i = 0; $i < $powS; $i++) {
          ExportXMLElement($n++, "clsE_SAddFunction", "ID$n", array("Type"=>"Base", "Fun"=>$S["_ID"][$i], "Var"=>$Calc["_ID"][0]));
      }
      for ($i = 0; $i < $powBound; $i++) {
          ExportXMLElement($n++, "clsE_SAddFunction", "ID$n", array("Type"=>"Bound", "Fun"=>$Bound["_ID"][$i], "Var"=>$Calc["_ID"][0]));
      }
      PutMail("COUNTER", $n);
    }
   } else if ($Stage == stResource && $EXPORT == "XML") {
      $n = GetNextMail("OBJS");
      $n += 1 + $powK + $powS + $powBound;
      PutMail("OBJS", $n);
   }
   PutMail("EXPORT",$EXPORT);
   return;
}

HandleParameter($Stage,$this->Kappa,$Calc["Nc"][0],$Kappa,$Solver["Parameters"],"Kappa".$Calc["Name"][0]);
HandleParameter($Stage,$this->NuMol,$Calc["Nc"][0],$NuMol,$Solver["Parameters"],"NuMol".$Calc["Name"][0]);
if ($Calc["Nc"][0]>1)
   {
    $SRef = array();
    for ($i=0; $i<$Calc["Nc"][0]; $i++)
        {
         cortege_push($Solver["Kappa"],$Kappa[0]."[".$i."]");
         cortege_push($Solver["NuMol"],$NuMol[0]."[".$i."]");
         cortege_push($Solver["NeedS"],$powS!=0);
         array_push($SRef,"Sf[_Num".$Calc["Name"][0].$i."]");
        }
    $SRef = "float * S_".$Calc["Name"][0]."[".$Calc["Nc"][0]."] = {".implode(",",$SRef)."};";
    cortege_push($Solver["Refs"],$SRef);
   }
else
   {
    $Solver["Kappa"] = $Kappa;
    $Solver["NuMol"] = $NuMol;
    cortege_push($Solver["NeedS"],$powS!=0);
   }
if ($powS!=0)
   {
    $Solver["Parameters"] = array_merge($Solver["Parameters"],$S["Parameters"]);
    AnalyzeFunctionItems($S,$powS,$Calc,$Solver,"FText","SText","SVars","S_","[Ptr]","Sf[_Num","][Ptr]","+=");
   }
?>
