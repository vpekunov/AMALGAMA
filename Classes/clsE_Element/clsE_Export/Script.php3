<?php
switch ($Stage) {
  case stResource:
    $EXPORT = GetNextMail("EXPORT");
    if ($EXPORT === "") {
       $EXPORT = $this->Lang;
    }
    if ($this->Lang == "XML") {
       SetXMLExportMode($this->ClassPath);
       WriteXMLExportHeader();
    }
    PutMail("EXPORT", $EXPORT);
    break;
  case stInit:
    if ($this->Lang == "XML") {
       $n = GetNextMail("OBJS");
       WriteXMLElementsQuantity($n);
       PutMail("COUNTER", 0);
    }
    break;
  case stDone:
    if ($this->Lang == "XML") {
       WriteXMLExportFooter();
    }
    break;
}

?>
