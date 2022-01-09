<?
$FNumDims = $From["NumDims"][0];
$TNumDims = $To["NumDims"][0];
if ($Stage==stResource) {
?>#PROCEDURE <?
   echo $this->ID,"(";
   echo $From["MapType"][0].",SrcMap;";
   echo $From["TypeName"][0].",Src;";
   echo $To["MapType"][0].",DestMap;";
   echo $To["TypeName"][0].",#BYREF".IfArray($TNumDims)."(Dest))\n";
   $Shift = "  ";
   $Letters = array("X","Y","Z");
   for ($i = 0; $i<$FNumDims; $i++) {
       echo $Shift;
?>#DEFVAR(#INT,P<? echo $Letters[$i],")\n";
   }
   CreateForLoop(true,$TNumDims,explode(";",$To["Dims"][0]),$LoopIDs,$Indexes,$Shift);
   echo $Shift;
   if ($TNumDims>0) {
?>#IF(#ISNOTBOUND(DestMap<? echo $Indexes,"))\n";
      echo $Shift,"  ";
   }
   $SrcIndexes = "";
   for ($i = 0; $i < $FNumDims; $i++) {
?>#SET(P<? echo $Letters[$i],",#TRUNC(".$To["Coords"][$i].$Indexes;
       echo "/".$From["Steps"][$i]."))\n";
       $SrcIndexes.="[P".$Letters[$i]."]";
       echo $Shift,"  ";
   }
?>#SET(#DEREF<?
   echo IfArray($TNumDims)."(Dest",$Indexes,"),Src".$SrcIndexes.")\n";
   if ($TNumDims>0) {
      echo $Shift,"#ELSE\n";
      echo $Shift,"  #SET(#DEREF",IfArray($TNumDims)."(Dest",$Indexes,"),0)\n";
      echo $Shift,"#ENDIF\n";
   }
   CloseForLoop($TNumDims,$Shift);
?>#ENDPROCEDURE
<?
}
cortege_push($Proj["Conjunctor"],$this->ID);
cortege_push($Proj["TypeName"],$To["TypeName"][0]);
cortege_push($Proj["BaseType"],$To["BaseType"][0]);
cortege_push($Proj["NumDims"],$To["NumDims"][0]);
cortege_push($Proj["Dims"],$To["Dims"][0]);
cortege_push($Proj["MapName"],$To["MapName"][0]);
cortege_push($Proj["MapType"],$To["MapType"][0]);
?>
