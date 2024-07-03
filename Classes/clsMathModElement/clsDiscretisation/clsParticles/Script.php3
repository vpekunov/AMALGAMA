<?php
if ($Stage==stResource)
   if ($this->NumParticles>1) {
?>#DEFARRAYTYPE(<?php echo $this->BaseType,",",$this->NumParticles,",",$this->ID,")\n";
?>#DEFARRAYTYPE(<?php echo "#CHAR,",$this->NumParticles,",",$this->ID,"_Map)\n";
   }
if ($this->NumParticles==1)
   cortege_push($Var["TypeName"],$this->BaseType);
else
   cortege_push($Var["TypeName"],$this->ID);
$NumDims = $this->NumParticles>1;
cortege_push($Var["BaseType"],$this->BaseType);
cortege_push($Var["NumDims"],$NumDims);
cortege_push($Var["Dims"],$this->NumParticles);
cortege_push($Var["NewName"],"");
$Map = $Var;
?>
