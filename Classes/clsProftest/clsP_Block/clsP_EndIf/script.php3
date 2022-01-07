<?
 if ($Stage===$this->Event || $Stage===$this->EventElse)
    if ($In["_ClassID"][0]=="clsP_Question" && $this->ClassID!="clsP_Question")
       echo ")\n";
 if ($Stage===$this->Event)
    echo $this->Prefix."EndIf\n";
 if ($Stage==stResource)
    {
     $this->Event = GetLastEvent(array($In["Event"][0],$Rev["Event"][0]));
     $this->Prefix = substr($In["Prefix"][0],2);
     if ($this->Event!=$Rev["Event"][0])
        MakeError("Model Error"," ".$this->ID.": End contact can be connected to reverse line only",__LINE__);
     $this->EventElse = $In["Event"][0];
     $C1 = count($In["Construct"]);
     $C2 = count($Rev["Construct"]);
     if ($C1==$C2)
        if ($C1==0)
           MakeError("Model Error"," ".$this->ID.": Different level of code on input lines",__LINE__);
        else
           {
            $A1 = array_pop($In["Construct"]);
            $A2 = array_pop($Rev["Construct"]);
            if ($A1!=$A2)
               MakeError("Model Error"," ".$this->ID.": Different IF-flows on input lines",__LINE__);
            $Out["Construct"] = $In["Construct"];
            cortege_push($Out["Prefix"],$this->Prefix);
           }
     else
        MakeError("Model Error"," ".$this->ID.": Different level of code on input lines",__LINE__);
     cortege_push($Out["Event"],$this->Event);
    }
?>