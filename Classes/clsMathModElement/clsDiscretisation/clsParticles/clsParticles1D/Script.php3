<?php
$VarX["TypeName"] = $Var["TypeName"];
$VarX["BaseType"] = $Var["BaseType"];
$VarX["NumDims"] = $Var["NumDims"];
$VarX["Dims"] = $Var["Dims"];
cortege_push($Map["Coords"],$this->ID."_X[#LOWDIM]");
cortege_push($VarX["NewName"],$this->ID."_X");
?>
