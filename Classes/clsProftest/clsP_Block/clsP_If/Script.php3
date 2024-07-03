<?php
 if ($Stage===$this->Event)
    {
     echo ShiftStr($this->Prefix,$this->Vars);
     echo $this->Prefix."If ".$this->Condition;
    }
 elseif ($Stage===$this->EventElse)
    echo $this->Prefix."Else\n";
 else
   switch ($Stage) {
     case stResource:
       $this->EventElse = CreateEventAfter($this->Event,__LINE__);
       cortege_push($Rev["Event"],$this->EventElse);
       $Out["Construct"] = $In["Construct"];
       unset($Out["Prefix"]);
       cortege_push($Out["Prefix"],$this->Prefix."  ");
       cortege_push($Out["Construct"],$this->ID);
       $Rev["Construct"] = $Out["Construct"];
       cortege_push($Rev["Prefix"],$this->Prefix."  ");
       break;
   }
?>