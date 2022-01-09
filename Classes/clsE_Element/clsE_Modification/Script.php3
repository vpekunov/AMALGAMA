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
?> Для вещества <? echo $Calc["_ID"][0]; ?> зададим модификатор <? echo $this->ID; ?>.<?
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
      ExportXMLElement($n++, "clsE_SModification", "ID$n", array("Var"=>$Calc["_ID"][0]));
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

$KRef = "float * K_".$Calc["Name"][0]." = KDn[SLinks[ref".$Calc["Substance"][0]."]];";
cortege_push($Solver["Refs"],$KRef);
$SRef = "float * S_".$Calc["Name"][0]." = SDn[SLinks[ref".$Calc["Substance"][0]."]];";
cortege_push($Solver["Refs"],$SRef);
$Ref = "DeclareDn(".$Calc["Name"][0].",SLinks[ref".$Calc["Substance"][0]."]);";
cortege_push($Solver["Refs"],$Ref);

cortege_push($Solver["Name"],$Calc["Name"][0]);
cortege_push($Solver["Substance"],$Calc["Substance"][0]);

if ($powK==0 && $powS==0 && $powBound==0)
   $Solver["Parameters"] = $Calc["Parameters"];
else
   {
    if ($powK==0)
       $Solver["Parameters"] = $Calc["Parameters"];
    else
       $Solver["Parameters"] = array_merge($Calc["Parameters"],$K["Parameters"]);
    if ($powS!=0)
       $Solver["Parameters"] = array_merge($Solver["Parameters"],$S["Parameters"]);
    if ($powBound!=0)
       $Solver["Parameters"] = array_merge($Solver["Parameters"],$Bound["Parameters"]);
    AnalyzeFunctionItems($K,$powK,$Calc,$Solver,"FText","FText","FVars","K_","[Ptr]","K_","[Ptr]","+=");
    AnalyzeFunctionItems($S,$powS,$Calc,$Solver,"FText","SText","SVars","S_","[Ptr]","S_","[Ptr]","+=");
    AnalyzeFunctionItems($Bound,$powBound,$Calc,$Solver,"FText","BText","BVars","if (IsBound && !IsExchng) ","","if (IsBound && !IsExchng) ","","=");
   }
?>
