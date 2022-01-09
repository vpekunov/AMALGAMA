<?
switch ($Stage) {
  case stResource:
    if ($this->TestID!="")
       {
        echo "%TestID=".$this->TestID."\n";
        if ($this->Description!="")
           {
            $L = strlen($this->Description)-1;
            if ($this->Description[$L]=="\n")
               $this->Description = substr($this->Description,0,$L);
            echo "%".str_replace("\n","\n%",$this->Description)."\n\n";
           }
       }
    cortege_push($Out["Event"],CreateEventAfter(stInit,__LINE__));
    cortege_push($Out["Prefix"],"  ");
    if ($this->Prompt!=="")
       {
        echo "Text(Prompt)\n";
        echo $this->Prompt;
        echo "EndT\n\n";
       }
    if ($this->Instruction!=="")
       {
        echo "Instruction\n";
        echo $this->Instruction;
        echo "EndI\n\n";
        PutMail("Instruction",1);
       }
    break;
  case stInit:
    echo "Main\n";
    echo "  Size(obWindow,".$this->Width.",".$this->Height.")\n";
    if ($this->Title!="")
       echo "  Title('".$this->Title."')\n";
    if ($this->Prompt!=="")
       echo "  ShowPrompt(Prompt)\n";
    break;
  case stDone:
    echo "  Exit\n";
    echo "EndM\n";
    break;
}
cortege_push($Out["Test"],1);
?>
