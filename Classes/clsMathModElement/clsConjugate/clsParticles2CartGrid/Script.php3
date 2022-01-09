<?
$FNumDims = (int)$From["NumDims"][0];
$TNumDims = (int)$To["NumDims"][0];
if ($Stage==stResource) {
?>#PROCEDURE <?
   echo $this->ID,"(";
   echo $From["MapType"][0].",SrcMap;";
   echo $From["TypeName"][0].",Src;";
   echo $To["MapType"][0].",DestMap;";
   echo $To["TypeName"][0].",#BYREF".IfArray($TNumDims)."(Dest))\n";
   $Shift = "  ";
   $Letters = array("X","Y","Z");
   for ($i = 0; $i<$TNumDims; $i++) {
       echo $Shift;
?>#DEFVAR(#INT,P<? echo $Letters[$i],")\n";
   }
   CreateLoopVars(max($FNumDims,$TNumDims),$LoopIDs);
   CreateForLoop(false,$TNumDims,explode(";",$To["Dims"][0]),$LoopIDs,$Indexes,$Shift);
   echo $Shift;
?>#SET(#DEREF<?
   echo IfArray($TNumDims)."(Dest",$Indexes,"),0)\n";
   CloseForLoop($TNumDims,$Shift);
   CreateForLoop(false,$FNumDims,explode(";",$From["Dims"][0]),$LoopIDs,$Indexes,$Shift);
   echo $Shift;
   if ($FNumDims>0) {
?>#IF(#ISNOTBOUND(SrcMap<? echo $Indexes,"))\n";
      echo $Shift,"  ";
   }
   $DestIndexes = "";
   for ($i = 0; $i < $TNumDims; $i++) {
?>#SET(P<? echo $Letters[$i],",#TRUNC(".$From["Coords"][$i].$Indexes;
       echo "/".$To["Steps"][$i]."))\n";
       $DestIndexes.="[P".$Letters[$i]."]";
       echo $Shift,"  ";
   }
   $Dst = "#DEREF".IfArray($TNumDims)."(Dest".$DestIndexes.")";
?>#SET(<? echo $Dst,",",$Dst,"+Src".$Indexes.")\n";
   if ($FNumDims>0) {
      echo $Shift;
?>#ENDIF
<?
   }
   CloseForLoop($FNumDims,$Shift);
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
