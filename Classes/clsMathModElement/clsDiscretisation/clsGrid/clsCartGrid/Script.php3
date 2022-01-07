<?
if ($Stage==stResource)
   if ($this->NumDims>0) {
    $Indexes = "";
    $DimArr = explode(";",$this->Dims);
    for ($i = 0; $i < $this->NumDims; $i++)
        $Indexes .= $DimArr[$i].",";
?>#DEFARRAYTYPE(<? echo $this->BaseType,",",$Indexes,$this->ID,")\n";
?>#DEFARRAYTYPE(<? echo "#CHAR,",$Indexes,$this->ID,"_Map)\n";
    $Steps = explode(";",$this->Steps);
    $Letters = array("X","Y","Z");
    for ($i = 0; $i < $this->NumDims; $i++) {
?>#DEFCONST(<? echo "#DOUBLE,",$this->ID,"_H".$Letters[$i],",",$Steps[$i],")\n";
        cortege_push($Var["Steps"],$this->ID."_H".$Letters[$i]);
    }
   }
if ($this->NumDims==0)
   cortege_push($Var["TypeName"],$this->BaseType);
else
   cortege_push($Var["TypeName"],$this->ID);
cortege_push($Var["BaseType"],$this->BaseType);
cortege_push($Var["NumDims"],$this->NumDims);
cortege_push($Var["Dims"],$this->Dims);
cortege_push($Var["NewName"],"");
$Map = $Var;
?>
