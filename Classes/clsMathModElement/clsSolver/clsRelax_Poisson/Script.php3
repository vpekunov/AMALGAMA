<?php
$Dims = explode(";",$Eqtn["FDims"][0]);
$NumDims = $Eqtn["FNumDims"][0];
switch ($Stage) {
 case stResource:
?>#DEFVAR(<?php echo $Eqtn["FTypeName"][0],",",$this->ID."_Buf)\n";
?>#PROCEDURE <?php
   echo $this->ID,"(",$NumDims>0 ? $Eqtn["FMapType"][0].",Map;" : "",$Eqtn["FTypeName"][0].",F;";
   echo $Eqtn["FTypeName"][0].",#BYREF".IfArray($NumDims)."(Fn);";
   echo $Eqtn["GTypeName"][0].",G;",$Eqtn["KTypeName"][0].",K;","#DOUBLE,TAU)\n";
?>  #DEFVAR(#DOUBLE,Delta)
  #DEFVAR(#DOUBLE,MaxDelta)
  #DEFVAR(#DOUBLE,QT)
<?php CreateLoopVars($NumDims,$LoopIDs);
   $HX = $Eqtn["FTypeName"][0]."_HX";
   $HY = $Eqtn["FTypeName"][0]."_HY";
   $HZ = $Eqtn["FTypeName"][0]."_HZ";
   switch ($NumDims) {
     case 1:
       echo "  #DEFVAR(#DOUBLE,QP)\n";
       echo "  #SET(QP,$HX*$HX)\n";
       echo "  #SET(QS,$this->Theta/2)\n";
       break;
     case 2:
       echo "  #DEFVAR(#DOUBLE,QX)\n";
       echo "  #DEFVAR(#DOUBLE,QY)\n";
       echo "  #DEFVAR(#DOUBLE,QS)\n";
       echo "  #DEFVAR(#DOUBLE,QP)\n";
       echo "  #SET(QX,$HY*$HY)\n";
       echo "  #SET(QY,$HX*$HX)\n";
       echo "  #SET(QS,$this->Theta/(QX+QY)/2)\n";
       echo "  #SET(QP,QX*QY)\n";
       break;
     case 3:
       echo "  #DEFVAR(#DOUBLE,SX)\n";
       echo "  #DEFVAR(#DOUBLE,SY)\n";
       echo "  #DEFVAR(#DOUBLE,SZ)\n";
       echo "  #DEFVAR(#DOUBLE,QX)\n";
       echo "  #DEFVAR(#DOUBLE,QY)\n";
       echo "  #DEFVAR(#DOUBLE,QZ)\n";
       echo "  #DEFVAR(#DOUBLE,QS)\n";
       echo "  #DEFVAR(#DOUBLE,QP)\n";
       echo "  #SET(SX,$HY*$HY)\n";
       echo "  #SET(SY,$HX*$HX)\n";
       echo "  #SET(SZ,$HZ*$HZ)\n";
       echo "  #SET(QX,SY*SZ)\n";
       echo "  #SET(QY,SX*SZ)\n";
       echo "  #SET(QZ,SX*SY)\n";
       echo "  #SET(QS,$this->Theta/(SX+SY+SZ)/2)\n";
       echo "  #SET(QP,SX*SY*SZ)\n";
       break;
   }
   echo "  #SET(QT,1-",$this->Theta,")\n";
   echo "  #COPY(#DEREFARRAY(",$this->ID."_Buf),#DEREFARRAY(F))\n";
?>  #SET(MaxDelta,1E10)
  #WHILE(MaxDelta #GE# <?php echo $this->Eps,")\n";
   $Shift = "    ";
   echo $Shift,"#SET(MaxDelta,0)\n";
   CreateForLoop(false,$NumDims,$Dims,$LoopIDs,$Indexes,$Shift);
   if ($NumDims>0) {
      echo $Shift; ?>#IF(#ISNOTBOUND(Map<?php echo $Indexes,"))\n";
      $Shift .= "  ";
   }
   $DerefPart = "#DEREF".IfArray($NumDims)."(";
   $SetPart = $Shift."#SET(".$DerefPart."Fn".$Indexes."),";
   echo $Shift,"#SET(Delta,";
   switch ($NumDims) {
     case 1:
       echo "QS*(F[i-1]+F[i+1]-G[i]*QP))\n";
       echo $SetPart,"QT*F[i]+Delta)\n";
       break;
     case 2:
       echo "QS*(F[i-1][j]*QX+F[i+1][j]*QX+F[i][j-1]*QY+F[i][j+1]*QY-G[i][j]*QP))\n";
       echo $SetPart,"QT*F[i][j]+Delta)\n";
       break;
     case 3:
       echo "QS*(F[i-1][j][k]*QX+F[i+1][j][k]*QX+F[i][j-1][k]*QY+F[i][j+1][k]*QY+F[i][j][k-1]*QZ+F[i][j][k+1]*QZ-G[i][j][k]*QP))\n";
       echo $SetPart,"QT*F[i][j][k]+Delta)\n";
       break;
   }
   echo $Shift,"#IF(#ABS(Delta) #GT# MaxDelta)\n";
   echo $Shift,"  #SET(MaxDelta,#ABS(Delta))\n";
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
?>    #COPY(#DEREFARRAY(F),#DEREFARRAY(Fn))
  #ENDWHILE
<?php  echo "  #COPY(#DEREFARRAY(F),#DEREFARRAY(",$this->ID."_Buf))\n";
?>#ENDPROCEDURE
<?php
   break;
 case stCall:
   $NumCalls =  _count($Eqtn["GValName"]);
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
