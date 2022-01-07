<?
$Dims = explode(";",$Eqtn["FDims"][0]);
$NumDims = $Eqtn["FNumDims"][0];
switch ($Stage) {
 case stResource:
?>#PROCEDURE <?
   echo $this->ID,"(",$NumDims>0 ? $Eqtn["FMapType"][0].",Map;" : "",$Eqtn["FTypeName"][0].",F;";
   echo $Eqtn["FTypeName"][0].",#BYREF".IfArray($NumDims)."(Fn);";
   echo $Eqtn["GTypeName"][0].",G;","#DOUBLE,TAU)\n";
   $Shift = "  ";
   CreateForLoop(true,$NumDims,$Dims,$LoopIDs,$Indexes,$Shift);
   if ($NumDims>0) {
      echo $Shift; ?>#IF(#ISNOTBOUND(Map<? echo $Indexes,"))\n";
   }
   $DerefPart = "#DEREF".IfArray($NumDims)."(";
   $SetPart = $Shift.($NumDims>0 ? "  " : "")."#SET(".$DerefPart."Fn".$Indexes."),";
   echo $SetPart."F".$Indexes,"+TAU*G".$Indexes,")\n";
   if ($NumDims>0) {
      echo $Shift; ?>#ELSE
<?    echo "  ".$Shift; ?>#IF(Map<? echo $Indexes," #EQ# '2')\n";
      $Bound2 = "#BOUND2_".$NumDims."D(Map,Fn,";
      for ($i = 0; $i < $NumDims; $i++)
          $Bound2 .= $LoopIDs[$i].",".$Dims[$i].($i<$NumDims-1 ? "," : ")");
      echo "  ".$SetPart,$Bound2,")\n";
      echo "  ".$Shift; ?>#ELSE
<?    echo "  ".$SetPart,$DerefPart."F".$Indexes."))\n";
      echo "  ".$Shift; ?>#ENDIF
<?    echo $Shift; ?>#ENDIF
<?
   }
   CloseForLoop($NumDims,$Shift);
?>#ENDPROCEDURE
<?
   break;
 case stCall:
   $NumCalls = count($Eqtn["GCallName"]);
   for ($i = 0; $i < $NumCalls; $i++) {
?>    #CALL <?
       echo $this->ID,"(",$NumDims>0 ? $Eqtn["FMapName"][$i]."," : "";
       echo $Eqtn["FValName"][$i]."[cnt".$Eqtn["FValName"][$i]."],".
            "#REF".IfArray($NumDims)."(".$Eqtn["FValName"][$i]."[cnt".$Eqtn["FValName"][$i]."+1]),";
       echo $Eqtn["GCallName"][$i].",Time)\n";
?>    #INCREMENT(<?
       echo "cnt".$Eqtn["FValName"][$i].",1)\n";
   }
   break;
}
$Prog["NumDims"] = $Eqtn["FNumDims"];
$Prog["CalcVarNames"] = $Eqtn["FValName"];
?>
