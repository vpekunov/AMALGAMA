<?php
if ($Stage===$this->Event)
   {
    if ($In["_ClassID"][0]=="clsP_Question" && $this->ClassID!="clsP_Question")
       echo ")\n";
    if (isset($In["Test"]))
       if ($this->ClassID=="clsP_Question")
          {
           echo "  Open\n";
           if (GetNextMail("Instruction")) {
?>  If Loading=0
     ShowInstruction
  EndIf
<?php         }
          }
       else
          $Out["Test"] = $In["Test"];
   }
switch ($Stage) {
  case stResource:
    $this->Event = GetLastEvent($In["Event"]);
    cortege_push($Out["Event"],$this->Event);
    $Out["Construct"] = $In["Construct"];
    $this->Prefix = $In["Prefix"][0];
    cortege_push($Out["Prefix"],$this->Prefix);
    break;
}
?>