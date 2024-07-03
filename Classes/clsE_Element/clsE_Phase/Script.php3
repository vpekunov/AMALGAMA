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
?> Введем <?php
      echo $Model["_LinkID"][0] == "Carrier" ? "несущую " : "прочую ";
      if ($this->Nc != 1)
         echo "мультифазу ".$this->ID." из ".$this->Nc." компонент ";
      else
         echo "фазу ".$this->ID." ";
      echo "на модели ".$Model["_ID"][0].".";
?> Скорость витания фазы <?php echo $this->ID; ?> приравняем "<?php echo $this->Uw; ?>".<?php
      if ($this->Source !== "") {
?> Источником фазы <?php echo $this->ID; ?> сделаем вещество <?php echo $this->Source; ?>.<?php
      }
      for ($i = 0; $i < $powSourceK; $i++) {
          ?> Присоединим правую функцию <?php echo $SourceK["_ID"][$i]; ?> к фазе <?php echo $this->ID; ?>.<?php
      }
      for ($i = 0; $i < $powSourceS; $i++) {
          ?> Присоединим базовую функцию <?php echo $SourceS["_ID"][$i]; ?> к фазе <?php echo $this->ID; ?>.<?php
      }
    } else if ($EXPORT == "XML") {
      $n = GetNextMail("COUNTER");
      if ($this->Nc == 1)
         ExportXMLElement($n++, "clsE_SPhase", "ID$n", array("Mode"=>$Model["_LinkID"][0], "Name"=>$this->ID, "Nc"=>$this->Nc, "Model"=>$Model["_ID"][0]));
      else
         ExportXMLElement($n++, "clsE_SMultiPhase", "ID$n", array("Mode"=>$Model["_LinkID"][0], "Name"=>$this->ID, "Nc"=>$this->Nc, "Model"=>$Model["_ID"][0]));
      ExportXMLElement($n++, "clsE_SPhase_Uw", "ID$n", array("Name"=>$this->ID, "Uw"=>$this->Uw));
      if ($this->Source !== "") {
         ExportXMLElement($n++, "clsE_SPhase_Source", "ID$n", array("Name"=>$this->ID, "Source"=>$this->Source));
      }
      for ($i = 0; $i < $powSourceK; $i++) {
          ExportXMLElement($n++, "clsE_SAddFunction", "ID$n", array("Type"=>"Right", "Fun"=>$SourceK["_ID"][$i], "Var"=>$this->ID));
      }
      for ($i = 0; $i < $powSourceS; $i++) {
          ExportXMLElement($n++, "clsE_SAddFunction", "ID$n", array("Type"=>"Base", "Fun"=>$SourceS["_ID"][$i], "Var"=>$this->ID));
      }
      PutMail("COUNTER", $n);
    }
   } else if ($Stage == stResource && $EXPORT == "XML") {
      $n = GetNextMail("OBJS");
      $n += 2 + $powSourceK + $powSourceS;
      if ($this->Source !== "") {
         $n++;
      }
      PutMail("OBJS", $n);
   }
   PutMail("EXPORT",$EXPORT);
   return;
}

HandleParameter($Stage,$this->Uw,$this->Nc,$Out,$Prms,"Uw".$this->ID);
$Data = array("Name" => $this->ID, "Uw" => $Out[0], "Source" => $this->Source, "Carrier" => $Model["_LinkID"][0]=="Carrier", "Nc" => $this->Nc);
if ($powSourceK!=0 || $powSourceS!=0)
   if ($this->Source!="")
      {
       if ($powSourceK!=0) $Data["Parameters"] = $SourceK["Parameters"];
       else $Data["Parameters"] = array();
       if ($powSourceS!=0) $Data["Parameters"] =  _array_merge($Data["Parameters"],$SourceS["Parameters"]);
       $Post = $this->Nc>1 ? "0" : "";
       if ($powSourceK!=0)
          {
           AnalyzeFunction($SourceK["FVars"][0],$SourceK["FText"][0],$this->ID.$Post);
           if ($this->Nc>1)
              $Data["FVars"] = HandleMultiFunction(true,$SourceK["FVars"][0],$this->Nc);
           else
              $Data["FVars"] = $SourceK["FVars"][0];
           $Data["FText"] =
              preg_replace("/(([^a-z0-9A-Z_])|(^))Result([ \n]*)=([ \n]*)(([^a-z0-9A-Z_])|($))/",
                           "\${1}KDn[PhaseLinks[ph".$this->ID.$Post."]][Ptr] += \${6}",
                           HandleMultiFunction(false,$SourceK["FText"][0],$this->Nc));
          }
       if ($powSourceS!=0)
          {
           AnalyzeFunction($SourceS["FVars"][0],$SourceS["FText"][0],$this->ID.$Post);
           if ($this->Nc>1)
              $Data["SVars"] = HandleMultiFunction(true,$SourceS["FVars"][0],$this->Nc);
           else
              $Data["SVars"] = $SourceS["FVars"][0];
           $Data["SText"] =
              preg_replace("/(([^a-z0-9A-Z_])|(^))Result([ \n]*)=([ \n]*)(([^a-z0-9A-Z_])|($))/",
                           "\${1}SDn[PhaseLinks[ph".$this->ID.$Post."]][Ptr] += \${6}",
                           HandleMultiFunction(false,$SourceS["FText"][0],$this->Nc));
          }
      }
   else
      MakeError("Model Error: ","Phase has no source to K-function",__LINE__);
cortege_push($U["Phase"],$Data);
cortege_push($Ro["Phase"],$Data);
cortege_push($T["Phase"],$Data);
cortege_push($Nu["Phase"],$Data);
cortege_push($Define["Phase"],$Data);
cortege_push($U["Nc"],$this->Nc);
cortege_push($Ro["Nc"],$this->Nc);
cortege_push($T["Nc"],$this->Nc);
cortege_push($Nu["Nc"],$this->Nc);
cortege_push($Define["Nc"],$this->Nc);
$U["Parameters"] = $Prms;
$Ro["Parameters"] = $Prms;
$T["Parameters"] = $Prms;
$Nu["Parameters"] = $Prms;
$Define["Parameters"] = $Prms;
?>
