<?php
switch ($Stage) {
 case stResource:
?>#PROGRAM
  #DEFVAR(#DOUBLE,EndTime)
  #DEFVAR(#DOUBLE,TAU)
  #DEFVAR(#DOUBLE,Time)
<?php
   break;
 case stInit:
?>  #SET(EndTime,<?php echo $this->EndTime; ?>)
  #SET(TAU,<?php echo $this->TAU; ?>)
  #SET(Time,0)
  #WHILE(Time #LT# EndTime)
<?php
   break;
 case stCall:
   $NumDims = $Solver["NumDims"][0];
   $VarNames = array();
   $CalcVarNum = count($Solver["CalcVarNames"]);
   for ($i = 0; $i < $CalcVarNum; $i++)
       if ($VarNames[$Solver["CalcVarNames"][$i]]=="")
          {
           $VarNames[$Solver["CalcVarNames"][$i]] = "+";
           if ($NumDims>0) {
?>    #COPY(<?php
             echo "#DEREFARRAY(".$Solver["CalcVarNames"][$i]."[#LOWDIM]),",
                  "#DEREFARRAY(".$Solver["CalcVarNames"][$i]."[cnt".$Solver["CalcVarNames"][$i]."]))\n";
           }
           else {
?>    #SET(<?php
             echo $Solver["CalcVarNames"][$i]."[#LOWDIM],",
                  $Solver["CalcVarNames"][$i]."[cnt".$Solver["CalcVarNames"][$i]."])\n";
           }
          }
?>    #SET(Time,Time+TAU)
  #ENDWHILE
<?php
   break;
 case stDone:
?>#ENDPROGRAM
<?php
   break;
}
?>
