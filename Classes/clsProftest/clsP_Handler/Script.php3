<?php
if ($Stage===$this->Event)
   {
    if ($In["_ClassID"][0]=="clsP_Question" && $this->ClassID!="clsP_Question")
       echo ")\n";
    if (isset($In["Test"]))
       {
        echo "  Open\n";
        if (GetNextMail("Instruction")) {
?>  If Loading=0
     ShowInstruction
  EndIf
<?php      }
       }
   }
switch ($Stage) {
  case stResource:
    $this->Event = GetLastEvent($In["Event"]);
    break;
  case stCall:
    if ($this->Save=="Yes")
       echo "  SaveResults\n";
    break;
}
?>