<?
if ($Stage==$this->Event)
   {
    $Buttons = array();
    if ($this->Instruction=="Yes") array_push($Buttons,"hbInstruction");
    if ($this->Back=="Yes") array_push($Buttons,"hbBack");
    if ($this->Forward=="Yes") array_push($Buttons,"hbForward");
    if ($this->Save=="Yes") array_push($Buttons,"hbSave");
    if ($this->Exit=="Yes") array_push($Buttons,"hbExit");
    if (count($Buttons)!=0)
       echo $this->Prefix."HandlePanel(".implode(",",$Buttons).")\n";
   }
?>