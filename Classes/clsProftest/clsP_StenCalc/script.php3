<?php
if ($Stage==stCall)
   {
    $P = $In["_ID"][0];
    $Barray  = explode(",",$this->Bounds);
    $NStens = count($Barray)+1;
    if ($NStens==1)
       MakeError("Model Error"," ".$this->ID.": Must be at least one bound",__LINE__);
    $NotFound = "nf".$this->ID;
    $Norm = "norm".$this->ID;
    echo "  Define $NotFound:Number = 1\n";
    echo "  Define $Norm:Array[2:$NStens] = {".$this->Bounds."}\n";
    echo "  Define ".$this->ID.":Number = $NStens\n";
    echo "  While (".$this->ID.">1 And $NotFound)\n";
    echo "    If ($P>=$Norm"."[".$this->ID."])\n";
    echo "       $NotFound:=0\n";
    echo "    Else\n";
    echo "       ".$this->ID.":=".$this->ID."-1\n";
    echo "    EndIf\n";
    echo "  EndW\n\n";
   }
cortege_push($Out["Name"],$this->Name);
?>