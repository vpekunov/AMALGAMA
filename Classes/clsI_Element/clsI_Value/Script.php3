<?php
  switch ($Stage) {
    case stResource:
      if (ReadNextMail($this->ID,"TIME")=="")
         PutMail("TIME",time());
      if (($this->MLab = ReadNextMail($this->ID,"MatLAB"))=="")
         {
          $this->MLab = com_load("Matlab.Application");
          com_set($this->MLab,"Visible",0);
         }
      cortege_push($Val["MatLab"],$this->MLab);
      $this->MLabDir = GetAns(com_invoke($this->MLab,"Execute","matlabroot"))."\\work";
      cortege_push($Val["MatLabDir"],$this->MLabDir);
      break;
    case stDone:
      cortege_push($Val["Function"],$this->ID);
      break;
    default:
      if (($NextEvent = ReadNextMail($this->ID,"NextEvent".$Stage))=="")
         {
          if ($Stage==stInit)
             $NextEvent = CreateEventAfter(stInit,__LINE__);
          else if ($Stage!=stDone)
             if (ReadNextMail($this->ID,$Stage))
                $NextEvent = CreateEventAfter($Stage,__LINE__);
          if ($NextEvent!="")
             PutMail("NextEvent".$Stage,$NextEvent);
         }

      if (isset($this->Inp))
         {
          cortege_push($Val["Value"],$this->Inp);
          cortege_push($Val["Events"],array($Stage));
          cortege_push($Val["Init"],$this->Init);
         }
      cortege_push($Val["R2Norm"],1E30);
      cortege_push($Val["Changed"],$Stage==stInit);
      cortege_push($Val["Event"],$NextEvent);
  }
?>