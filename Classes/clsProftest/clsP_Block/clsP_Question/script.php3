<?php
if ($Stage===$this->Event)
   {
    if ($In["_ClassID"][0]=="clsP_Question")
       echo ",";
    else
       echo $this->Prefix."Ask(";
    echo $this->ID;
   }
switch ($Stage) {
  case stResource:
    echo "Question(".$this->ID."):".$Answ[0]."\n";
    echo $this->Descriptor;
    echo "EndQ\n\n";
    break;
}
?>