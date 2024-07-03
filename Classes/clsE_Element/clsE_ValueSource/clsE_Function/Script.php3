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
   $phase = $powPhase == 0 ? "-" : $Phase["_ID"][0];
   if ($Stage == stCall) {
     if ($EXPORT == "Russian") {
?> Введем функцию <?php echo $this->ID; ?>, возвращающую выражение "<?php echo trim($this->Expression); ?>" на фазе "<?php echo $phase; ?>".<?php
      if (trim($this->Vars) !== "") {
          ?> Введем для функции <?php echo $this->ID; ?> вспомогательные определения "<?php echo trim($this->Vars); ?>".<?php
      }
     } else if ($EXPORT == "XML") {
       $n = GetNextMail("COUNTER");
       ExportXMLElement($n++, "clsE_SFun", "ID$n", array("Name"=>$this->ID, "Expression"=>trim($this->Expression), "Phase"=>$phase));
       if (trim($this->Vars) !== "") {
           ExportXMLElement($n++, "clsE_SFun_Vars", "ID$n", array("Name"=>$this->ID, "Vars"=>trim($this->Vars)));
       }
       PutMail("COUNTER", $n);
     }
   } else if ($Stage == stResource && $EXPORT == "XML") {
      $n = GetNextMail("OBJS");
      $n++;
      if (trim($this->Vars) !== "") {
          $n++;
      }
      PutMail("OBJS", $n);
   }
   PutMail("EXPORT",$EXPORT);
   return;
}

$this->Expression = UnrollIfNotExport($this->Expression);
$this->Vars = UnrollIfNotExport($this->Vars);

if ($powPhase>0)
   {
    HandleMultiFExpression($this->Expression,$Phase["Nc"][0]);
    $this->Vars = HandleMultiFunction(true,$this->Vars,$Phase["Nc"][0]);
    AnalyzeFunction($this->Vars,$this->Expression,$Phase["Phase"][0]["Name"].($Phase["Nc"][0]>1 ? "0" : ""));
   }
cortege_push($Val["FVars"],ExtractParams($this->Vars,$Val["Parameters"]));
cortege_push($Val["FText"],ExtractParams($this->Expression,$Val["Parameters"]));
?>
