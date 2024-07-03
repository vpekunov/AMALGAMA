<?php
if ($Stage==stResource)
   {
    $X["From"] = $In["_ID"][0];
    $X["To"] = $this->ID;

    PutMail("OUTStructure", $X);

    PutMail($this->ID, $this->Weight);
   }
?>