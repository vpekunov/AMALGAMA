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
?> Введем вектор <?php echo $this->ID; ?> с расширением "<?php echo $this->FBase; ?>" на фазе <?php echo $Phase["_ID"][0]; ?>.<?php
      $Params = array("Ro"=>"плотностью", "U"=>"скоростью", "T"=>"температурой", "Nu"=>"турбулентной вязкостью");
      for ($i = 0; $i < $powPhasePrm; $i++) {
          if ($PhasePrm["_ClassID"][$i] == "clsE_Model") {
?> Зададим контроль фазы <?php echo $Phase["_ID"][0]; ?> по переменной <?php echo $this->ID; ?>.<?php
          } else {
?> Назначением переменной <?php echo $this->ID; ?> сделаем <?php echo $Params[$PhasePrm["_LinkID"][$i]]; ?> фазы <?php echo $Phase["_ID"][0]; ?>.<?php
          }
      }
      if (trim($this->Desc) !== "") {
          ?> Дадим описание переменной <?php echo $this->ID; ?> как "<?php echo trim($this->Desc); ?>".<?php
      }
     } else if ($EXPORT == "XML") {
       $n = GetNextMail("COUNTER");
       ExportXMLElement($n++, "clsE_SVar", "ID$n", array("Type"=>"Vector", "Name"=>$this->ID, "Ext"=>$this->FBase, "Phase"=>$Phase["_ID"][0]));
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
       PutMail("COUNTER", $n);
     }
   } else if ($Stage == stResource && $EXPORT == "XML") {
      $n = GetNextMail("OBJS");
      $n += $powPhasePrm;
      $n++;
      if (trim($this->Desc) !== "") {
          $n++;
      }
      PutMail("OBJS", $n);
   }
   PutMail("EXPORT",$EXPORT);
   return;
}

cortege_push($Vx["FBase"],$this->FBase);
$Vx["Phase"] = $PhasePrm["Phase"];
if ($Phase["Nc"][0]>1)
   foreach ($PhasePrm["Phase"] as $Val)
     if ($Val["Name"]!=$Phase["Phase"][0]["Name"])
        MakeError("Model Error","Multiphase variable can't be a parameter of another phase",__LINE__);

$Vx["Nc"] = $Phase["Nc"];
$Vx["Parameters"] = $Phase["Parameters"];
cortege_push($Vx["Description"],$this->Desc);
if ($powPhasePrm>0) cortege_push($Vx["Phase"],$Phase["Phase"][0]);
cortege_push($Vx["DefPhase"],$Phase["_ID"][0]);
if ($powPhasePrm>0)
   if (in_array($Phase["_ID"][0],$PhasePrm["_ID"])) $Vx["Phase"][0]["Heavy"] = 1;

$Vy = $Vx;
$Vz = $Vx;

cortege_push($Vx["Projection"],0);
cortege_push($Vy["Projection"],1);
cortege_push($Vz["Projection"],2);
?>
