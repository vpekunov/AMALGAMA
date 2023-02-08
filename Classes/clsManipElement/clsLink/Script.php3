<?php
if ($powIn==0) $Num = 1;
else $Num = $In["Number"]+1;
if ($Stage==stResource)
   {
    if ($Num==1) echo "syms a;\n";
    echo "T".$Num." = subs(".$this->Matrix.",'a','".$this->Var."',0);\n";
   }
$Out = $In;
$Out["Number"] = $Num;
if ($this->Type!="Static")
   {
    cortege_push($Out["Handle"], "'" . ($Handle["Function"]=="" ? "0" : $Handle["Function"]) . "'");
    cortege_push($Out["dVars"], "'" . $this->Var . "(t)'");
    cortege_push($Out["Init"],$this->V0);
    cortege_push($Out["Init"],$this->F0);
   }
cortege_push($Out["Kinds"],$this->Kind);
cortege_push($Out["Axes"],$this->Axe);
cortege_push($Out["sVars"],"'".$this->Var."'");
cortege_push($Out["Vars"],"'" . $this->Var . ($this->Type=="Static" ? "" : "(t)") . "'");
cortege_push($Out["Moving"],$this->Moving==0 ? "0" : "1");
cortege_push($Out["Mins"],$this->vMin == "" ? "-Inf" : $this->vMin);
cortege_push($Out["Maxes"],$this->vMax == "" ? "Inf" : $this->vMax);
?>
