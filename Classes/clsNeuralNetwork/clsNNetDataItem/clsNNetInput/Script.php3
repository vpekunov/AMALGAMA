<?php
  $OutName = "\$" . $this->ID . "_Out";

  if ($Stage == stDone) {
     PutMail("X" . $this->NNum, $this->Num);
  }

  cortege_push($Out["OutName"], $OutName);
  cortege_push($Out["OutNum"], $this->NNum);
?>