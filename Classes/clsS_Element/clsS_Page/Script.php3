<?php
  ChangeOutput($this->FName,$Stage!=stResource);
  switch ($Stage) {
    case stInit: if ($this->Template==="") {
?><HTML>
<BODY>
<?php               }
                 break;
    case stCall: if ($this->Template!=="") {
                    foreach ($Forms["Items"] As $Val) {
                      $Val[1] = addslashes($Val[1]);
                      eval("\$$Val[0]=\"$Val[1]\";");
                    }
                    $Code = "echo \"".addslashes($this->Template)."\";";
                    eval($Code);
                 } else
                    echo implode("\n",$Forms["HTML"]);
                 break;
    case stDone: if ($this->Template==="") {
?></BODY>
</HTML>
<?php               }
                 break;
  }
?>