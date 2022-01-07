<?
if ($Stage==stResource)
   {
    foreach ($In["_ID"] as $Key=>$Val) {
      $P["From"] = $Val;
      $P["To"] = $this->ID;

      PutMail("INStructure", $P);
    }
    PutMail($this->ID, $this->InitP);
   }
?>