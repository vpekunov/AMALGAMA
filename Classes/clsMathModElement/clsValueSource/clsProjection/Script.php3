<?
switch ($Stage) {
 case stResource:
?>#DEFVAR(<?
   echo $Conj["TypeName"][0],",",$this->ID,")\n";
   break;
 case stCall:
   echo $Shift,"    ","#CALL ".$Conj["Conjunctor"][0]."(".
        $Proj["MapName"][0].",".$Proj["CallName"][0].",".
        $Conj["MapName"][0].",".
        "#REF".IfArray($Conj["NumDims"][0])."(".$this->ID."))\n";
   break;
}
$Val = $Conj;
cortege_push($Val["ValName"],$this->ID);
cortege_push($Val["CallName"],$this->ID);
?>
