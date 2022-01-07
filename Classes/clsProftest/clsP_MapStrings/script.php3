<?
$ID = $this->ID;
if ($Stage==stCall)
   {
    $Min    = $this->Min;
    $Texts  = $this->Texts;
    $Tarray = explode(',',$Texts);
    $NTexts = count($Tarray);
    $Max    = $Min+$NTexts-1;
    $Def    = "  Define $ID:Array[$Min:$Max] = {";
    $Map    = "  Define text$ID:Array[$Min:$Max] = {";

    for ($i=0; $i<$NTexts; $i++)
      {
       $Str = trim($Tarray[$i]);
       if ($Str[0]=="'")
          {
           echo "  Define $ID$i:String = $Str\n";
           $Def .= "#$ID$i";
           $Map .= "0";
          }
       else
          {
           $Def .= "#".$Str;
           $Map .= "1";
          }
       $Def .= ($i==$NTexts-1 ? "}" : ",");   
       $Map .= ($i==$NTexts-1 ? "}" : ",");   
      }
    echo $Def."\n";
    echo $Map."\n";
   }
$Out["Name"] = $In["Name"];
cortege_push($Out["Var$ID"],$In["_ID"][0]);
?>