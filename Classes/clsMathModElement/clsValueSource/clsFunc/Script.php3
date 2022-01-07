<?
$NumPrms = count($Arg["ValName"]);
$NumDims = $Arg["NumDims"][0];
switch ($Stage) {
 case stResource:
?>#DEFVAR(<?
   echo $Arg["TypeName"][0],",",$this->ID,"_Result)\n";
?>#PROCEDURE <?
   echo $this->ID,"(";
   if ($NumDims>0) echo $Arg["MapType"][0].",Map;";
   for ($i = 0; $i<$NumPrms; $i++)
       echo $Arg["TypeName"][$i].",".$Arg["ValName"][$i],";";
   echo $Arg["TypeName"][0].",#BYREF".IfArray($NumDims)."(".$this->ID,"_Result))\n";
   $Shift = "  ";
   CreateForLoop(true,$NumDims,explode(";",$Arg["Dims"][0]),$LoopIDs,$Indexes,$Shift);
   $Letters = array("X","Y","Z");
   $Dims = explode(";",$Arg["Dims"][0]);
   $Head = "_".$NumDims."D";
   $Tag = "";
   for ($i = 0; $i < $NumDims; $i++)
       $Tag .= $LoopIDs[$i].",".$Dims[$i].",".$Arg["TypeName"][0]."_H".$Letters[$i].",";
   for ($i = 0; $i<$NumPrms; $i++)
       if ($Arg["Dims"][$i]>0)
           $this->Expression = ereg_replace("(([^a-z0-9A-Z_@])|(^))".$Arg["ValName"][$i]."(([^a-z0-9A-Z_])|($))",
                                            "\\1".$Arg["ValName"][$i].$Indexes."\\4",
                                            $this->Expression);
   $this->Expression = ereg_replace("@([a-z0-9A-Z_]+)\\(",
                                    "#\\1".$Head."(".$Tag,
                                    $this->Expression);
   $this->Expression = str_replace("@","",$this->Expression);
   echo $Shift;
   if ($NumDims>0) {
?>#IF(#ISNOTBOUND(Map<? echo $Indexes,"))\n";
      echo $Shift,"  ";
   }
?>#SET(#DEREF<?
   echo IfArray($NumDims)."(";
   echo $this->ID."_Result",$Indexes,"),", $this->Expression,")\n";
   if ($NumDims>0) {
      echo $Shift,"#ELSE\n";
      echo $Shift,"  #SET(#DEREF".IfArray($NumDims)."(".$this->ID."_Result",
           $Indexes,"),0)\n";
      echo $Shift,"#ENDIF\n";
   }
   CloseForLoop($NumDims,$Shift);
?>#ENDPROCEDURE
<?
   break;
 case stCall:
?>    #CALL <?
   echo $this->ID,"(";
   if ($NumDims>0) echo $Arg["MapName"][0].",";
   for ($i = 0; $i<$NumPrms; $i++)
       echo $Arg["CallName"][$i].",";
   echo "#REF".IfArray($NumDims)."(".$this->ID."_Result))\n";
   break;
}
cortege_push($Val["ValName"],$this->ID."_Result");
cortege_push($Val["CallName"],$this->ID."_Result");
cortege_push($Val["TypeName"],$Arg["TypeName"][0]);
cortege_push($Val["BaseType"],$Arg["BaseType"][0]);
cortege_push($Val["NumDims"],$Arg["NumDims"][0]);
cortege_push($Val["Dims"],$Arg["Dims"][0]);
cortege_push($Val["MapName"],$Arg["MapName"][0]);
cortege_push($Val["MapType"],$Arg["MapType"][0]);
?>
