<?php
$Dims = explode(";",$Eqtn["FDims"][0]);
$NumDims = $Eqtn["FNumDims"][0];
switch ($Stage) {
 case stResource:
?>#PROCEDURE <?php
   echo $this->ID,"(",$NumDims>0 ? $Eqtn["FMapType"][0].",Map;" : "",$Eqtn["FTypeName"][0].",F;";
   echo $Eqtn["FTypeName"][0].",#BYREF".IfArray($NumDims)."(Fn);";
   echo $Eqtn["GTypeName"][0].",G;",$Eqtn["KTypeName"][0].",K;","#DOUBLE,TAU)\n";
   $Shift = "  ";
   CreateForLoop(true,$NumDims,$Dims,$LoopIDs,$Indexes,$Shift);
   if ($NumDims>0) {
      echo $Shift; ?>#IF(#ISNOTBOUND(Map<?php echo $Indexes,"))\n";
      $Shift .= "  ";
   }
   $DerefPart = "#DEREF".IfArray($NumDims)."(";
   $SetPart = $Shift."#SET(".$DerefPart."Fn".$Indexes."),";
   echo $Shift,"#IF(#ABS(K".$Indexes.") #GT# ",$this->Eps,")\n";
   echo "  ".$SetPart."F".$Indexes."+TAU*G".$Indexes."/K".$Indexes.")\n";
   echo $Shift,"#ELSE\n";
   echo "  ".$SetPart,$DerefPart."F".$Indexes."))\n";
   echo $Shift,"#ENDIF\n";
   if ($NumDims>0) {
      echo substr($Shift,0,-2); ?>#ELSE
<?php    echo $Shift; ?>#IF(Map<?php echo $Indexes," #EQ# '2')\n";
      $Bound2 = "#BOUND2_".$NumDims."D(Map,Fn,";
      for ($i = 0; $i < $NumDims; $i++)
          $Bound2 .= $LoopIDs[$i].",".$Dims[$i].($i<$NumDims-1 ? "," : ")");
      echo "  ".$SetPart,$Bound2,")\n";
      echo $Shift; ?>#ELSE
<?php    echo "  ".$SetPart,$DerefPart."F".$Indexes."))\n";
      echo $Shift; ?>#ENDIF
<?php    $Shift = substr($Shift,0,-2);
      echo $Shift; ?>#ENDIF
<?php
   }
   CloseForLoop($NumDims,$Shift);
?>#ENDPROCEDURE
<?php
   break;
 case stCall:
   $NumCalls = count($Eqtn["GValName"]);
   for ($i = 0; $i < $NumCalls; $i++) {
?>    #CALL <?php
       echo $this->ID,"(",$NumDims>0 ? $Eqtn["FMapName"][$i]."," : "";
       echo $Eqtn["FValName"][$i]."[cnt".$Eqtn["FValName"][$i]."],".
            "#REF".IfArray($NumDims)."(".$Eqtn["FValName"][$i]."[cnt".$Eqtn["FValName"][$i]."+1]),";
       echo $Eqtn["GCallName"][$i].",".$Eqtn["KCallName"][$i].",Time)\n";
?>    #INCREMENT(<?php
       echo "cnt".$Eqtn["FValName"][$i].",1)\n";
   }
   break;
}
$Prog["NumDims"] = $Eqtn["FNumDims"];
$Prog["CalcVarNames"] = $Eqtn["FValName"];
?>
