<?php
$MapType = $Discr["NumDims"][0]>0 ? $Discr["TypeName"][0]."_Map" : "#CHAR";
switch ($Stage) {
 case stResource:
?>#DEFVAR(<?php echo $MapType,",",$this->ID,")\n";
?>#DEFVAR(#FILE,<?php echo $this->ID."_File)\n";
   break;
 case stInit:
?>  #FILEOPEN(<?php echo $this->ID."_File,'",$this->FileName,"')\n";
?>  #FILEREAD(<?php echo $this->ID."_File,#REF".IfArray($Discr["NumDims"][0]);
   echo "(",$this->ID,"),#SIZE(",$MapType,"))\n";
   break;
 case stDone:
?>  #FILECLOSE(<?php echo $this->ID."_File)\n";
   break;
}
cortege_push($Cond["TypeName"],$MapType);
cortege_push($Cond["ValName"],$this->ID);
$Conj = $Discr;
cortege_push($Conj["MapType"],$MapType);
cortege_push($Conj["MapName"],$this->ID);
?>
