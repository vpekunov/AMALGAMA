<?php
  if ($Stage===$this->Event)
     {
      if ($this->Save=="Yes")
         echo $this->Prefix."SaveResults\n";
      echo $this->Prefix."StopTimer\n";
     }
?>