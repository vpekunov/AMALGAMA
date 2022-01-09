<?
$NumDims = $Discr["NumDims"][0];
$Type = $Discr["TypeName"][0];
$MapName = $Init["ValName"][0];
$MapType = $Init["TypeName"][0];
if ($Discr["NewName"][0]!="") $this->ID = $Discr["NewName"][0];
switch ($Stage) {
 case stResource:
?>#DEFARRAYVAR(<?
   echo $Type,",",$this->ID,",",$powCalc+1,")\n";
?>#DEFVAR(<?
   echo "#INT,cnt",$this->ID,")\n";
?>#PROCEDURE <?
   echo $this->ID,"_Init(".$MapType.",".$MapName.";";
   echo $Type.",#BYREF".IfArray($NumDims)."(".$this->ID,"))\n";
   $Shift = "  ";
   $Symbols = array_merge($Init["Symbol"],$Bound["Symbol"]);
   $Values = array_merge($Init["Value"],$Bound["Value"]);
   CreateForLoop(true,$NumDims,explode(";",$Discr["Dims"][0]),$LoopIDs,$Indexes,$Shift);
   CreateSetSelector($Shift,$MapName.$Indexes,
      "#DEREF".IfArray($NumDims)."(".$this->ID.$Indexes.")",
      $Symbols,$Values,"0");
   CloseForLoop($NumDims,$Shift);
?>#ENDPROCEDURE
<?
   break;
 case stInit:
?>  #CALL <?
   echo $this->ID,"_Init(",$MapName,",#REF".IfArray($NumDims)."(".$this->ID."[#LOWDIM]))\n";
   break;
 case stCall:
?>    #SET(<?
   echo "cnt",$this->ID,",#LOWDIM)\n";
   break;
}
cortege_push($Val["ValName"],$this->ID);
cortege_push($Val["CallName"],$this->ID."[#LOWDIM]");
cortege_push($Val["TypeName"],$Discr["TypeName"][0]);
cortege_push($Val["BaseType"],$Discr["BaseType"][0]);
cortege_push($Val["NumDims"],$Discr["NumDims"][0]);
cortege_push($Val["Dims"],$Discr["Dims"][0]);
cortege_push($Val["MapName"],$MapName);
cortege_push($Val["MapType"],$MapType);
cortege_push($Calc["ValName"],$this->ID);
cortege_push($Calc["TypeName"],$Discr["TypeName"][0]);
cortege_push($Calc["BaseType"],$Discr["BaseType"][0]);
cortege_push($Calc["NumDims"],$Discr["NumDims"][0]);
cortege_push($Calc["Dims"],$Discr["Dims"][0]);
cortege_push($Calc["MapName"],$MapName);
cortege_push($Calc["MapType"],$MapType);
?>
