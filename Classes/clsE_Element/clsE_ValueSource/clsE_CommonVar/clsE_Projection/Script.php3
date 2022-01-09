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
?> Введем проекцию <? echo $Vector["_LinkID"][0]; ?> вектора "<? echo $Vector["_ID"][0]; ?>" с именем <? echo $this->ID; ?>.<?
      if (trim($this->Init) !== "") {
          ?> Определим начальное значение переменной <? echo $this->ID; ?> как "<? echo trim($this->Init); ?>".<?
      }
      if ($this->Restrict !== "Any") {
          ?> Пусть переменная <? echo $this->ID; ?> будет иметь <? echo $this->Restrict == "Positive" ? "положительное" : "отрицательное"; ?> значение.<?
      }
     } else if ($EXPORT == "XML") {
       $n = GetNextMail("COUNTER");
       ExportXMLElement($n++, "clsE_SProjection", "ID$n", array("Type"=>$Vector["_LinkID"][0], "Name"=>$this->ID, "Vector"=>$Vector["_ID"][0]));
       if (trim($this->Init) !== "") {
           ExportXMLElement($n++, "clsE_SVar_Init", "ID$n", array("Name"=>$this->ID, "Init"=>trim($this->Init)));
       }
       if ($this->Restrict !== "Any") {
           ExportXMLElement($n++, "clsE_SVar_Restrict", "ID$n", array("Name"=>$this->ID, "Restrict"=>trim($this->Restrict)));
       }
       PutMail("COUNTER", $n);
     }
   } else if ($Stage == stResource && $EXPORT == "XML") {
      $n = GetNextMail("OBJS");
      $n++;
      if (trim($this->Init) !== "") {
          $n++;
      }
      if ($this->Restrict !== "Any") {
          $n++;
      }
      PutMail("OBJS", $n);
   }
   PutMail("EXPORT",$EXPORT);
   return;
}

$Axes = array("x","y","z");
$Name = $Vector["_ID"][0].$Axes[$Vector["Projection"][0]];

$Calc["Parameters"] = $Vector["Parameters"];
HandleInitParameter($Stage,$this->Init,$Vector["Nc"][0],$Calc["Init"],$Calc["Parameters"],"Zero".$Name);

$Calc["Projection"] = $Vector["Projection"];
$Calc["FBase"] = $Vector["FBase"];
cortege_push($Calc["Name"],$Name);
cortege_push($Calc["Restrict"],$this->Restrict);
if (is_array($Vector["Phase"]))
  foreach ($Vector["Phase"] as $Key => $Val)
    $Vector["Phase"][$Key]["V".$Axes[$Vector["Projection"][0]]] = "_Num".$Name;
$Calc["Phase"] = $Vector["Phase"];
$Calc["DefPhase"] = $Vector["DefPhase"];
$Calc["Nc"] = $Vector["Nc"];
$Calc["Description"] = $Vector["Description"];
cortege_push($Val["Name"],$Name);
cortege_push($Val["FText"],$Name.($Vector["Nc"][0]>1 ? "[i]" : "").";");
$Val["Nc"] = $Vector["Nc"];
?>
