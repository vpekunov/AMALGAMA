<?
switch ($Stage) {
 case stResource:
?>#PROGRAM
  #DEFVAR(#DOUBLE,EndTime)
  #DEFVAR(#DOUBLE,TAU)
  #DEFVAR(#DOUBLE,Time)
<?
   break;
 case stInit:
?>  #SET(EndTime,<? echo $this->EndTime; ?>)
  #SET(TAU,<? echo $this->TAU; ?>)
  #SET(Time,0)
  #WHILE(Time #LT# EndTime)
<?
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
?>    #COPY(<?
             echo "#DEREFARRAY(".$Solver["CalcVarNames"][$i]."[#LOWDIM]),",
                  "#DEREFARRAY(".$Solver["CalcVarNames"][$i]."[cnt".$Solver["CalcVarNames"][$i]."]))\n";
           }
           else {
?>    #SET(<?
             echo $Solver["CalcVarNames"][$i]."[#LOWDIM],",
                  $Solver["CalcVarNames"][$i]."[cnt".$Solver["CalcVarNames"][$i]."])\n";
           }
          }
?>    #SET(Time,Time+TAU)
  #ENDWHILE
<?
   break;
 case stDone:
?>#ENDPROGRAM
<?
   break;
}
?>
