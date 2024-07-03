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
?> Введем скаляр <?php echo $this->ID; ?> с расширением "<?php echo $this->FBase; ?>" на фазе <?php echo $Phase["_ID"][0]; ?>.<?php
      $Params = array("Ro"=>"плотностью", "U"=>"скоростью", "T"=>"температурой", "Nu"=>"турбулентной вязкостью");
      for ($i = 0; $i < $powPhasePrm; $i++) {
          if ($PhasePrm["_ClassID"][$i] == "clsE_Model") {
?> Зададим контроль фазы <?php echo $Phase["_ID"][0]; ?> по переменной <?php echo $this->ID; ?>.<?php
          } else {
?> Пусть переменная <?php echo $this->ID; ?> будет <?php echo $Params[$PhasePrm["_LinkID"][$i]]; ?> фазы <?php echo $Phase["_ID"][0]; ?>.<?php
          }
      }
      if (trim($this->Desc) !== "") {
          ?> Дадим описание переменной <?php echo $this->ID; ?> как "<?php echo trim($this->Desc); ?>".<?php
      }
      if (trim($this->Init) !== "") {
          ?> Определим начальное значение переменной <?php echo $this->ID; ?> как "<?php echo trim($this->Init); ?>".<?php
      }
      if ($this->Restrict !== "Any") {
          ?> Пусть переменная <?php echo $this->ID; ?> будет иметь <?php echo $this->Restrict == "Positive" ? "положительное" : "отрицательное"; ?> значение.<?php
      }
     } else if ($EXPORT == "XML") {
       $n = GetNextMail("COUNTER");
       ExportXMLElement($n++, "clsE_SVar", "ID$n", array("Type"=>"Scalar", "Name"=>$this->ID, "Ext"=>$this->FBase, "Phase"=>$Phase["_ID"][0]));
       $Params = array("Ro"=>"плотностью", "U"=>"скоростью", "T"=>"температурой", "Nu"=>"турбулентной вязкостью");
       for ($i = 0; $i < $powPhasePrm; $i++) {
           if ($PhasePrm["_ClassID"][$i] == "clsE_Model") {
              ExportXMLElement($n++, "clsE_SVar_Control", "ID$n", array("ControlVar"=>$this->ID, "Phase"=>$Phase["_ID"][0]));
           } else {
              ExportXMLElement($n++, "clsE_SVar_Is", "ID$n", array("Var"=>$this->ID, "Type"=>$PhasePrm["_LinkID"][$i], "Phase"=>$Phase["_ID"][0]));
           }
       }
       if (trim($this->Desc) !== "") {
           ExportXMLElement($n++, "clsE_SVar_Description", "ID$n", array("Name"=>$this->ID, "Desc"=>trim($this->Desc)));
       }
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
      $n += $powPhasePrm;
      $n++;
      if (trim($this->Desc) !== "") {
          $n++;
      }
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

$Calc["Parameters"] = $Phase["Parameters"];
HandleInitParameter($Stage,$this->Init,$Phase["Nc"][0],$Calc["Init"],$Calc["Parameters"],"Zero".$this->ID);

cortege_push($Calc["Description"],$this->Desc);
cortege_push($Calc["Projection"],-1);
cortege_push($Calc["FBase"],$this->FBase);
cortege_push($Calc["Name"],$this->ID);
cortege_push($Calc["Restrict"],$this->Restrict);

for ($i=0; $i<$powPhasePrm; $i++)
    {
     $PhasePrm["Phase"][$i][$PhasePrm["_LinkID"][$i]] = "_Num".$this->ID;
     if ($Phase["Nc"][0]>1 && $PhasePrm["Phase"][$i]["Name"]!=$Phase["Phase"][0]["Name"])
        MakeError("Model Error","Multiphase variable can't be a parameter of another phase",__LINE__);
    }
for ($i=0; $i<$powPhasePrm; $i++)
    if ($PhasePrm["_LinkID"][$i]=="Control")
       if ($Phase["Nc"][0]>1)
          MakeError("Model Error","Multiphase variable can't be an accuracy control variable",__LINE__);
       else
          cortege_push($Calc["Control"],"_Num".$this->ID);
    else
       cortege_push($Calc["Phase"],$PhasePrm["Phase"][$i]);
cortege_push($Calc["Phase"],$Phase["Phase"][0]);
cortege_push($Calc["DefPhase"],$Phase["_ID"][0]);
$Calc["Nc"] = $Phase["Nc"];
cortege_push($Val["Name"],$this->ID);
cortege_push($Val["FText"],$this->ID.($Phase["Nc"][0]>1 ? "[i]" : "").";");
$Val["Nc"] = $Phase["Nc"];
?>
