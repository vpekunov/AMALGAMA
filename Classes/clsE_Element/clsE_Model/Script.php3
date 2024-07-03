<?php
$EXPORT = GetNextMail("EXPORT");
if ($EXPORT === "") {
   global $XML;
   $ref = $XML->match("/System/Elements/Element[@ClassID='clsE_Export']/Parameters/Parameter[@ID='Lang']/text()");
   if ($ref[0] != "") {
       $EXPORT = $XML->wholeText($ref[0]);
   }
}
if ($EXPORT !== "") {
   SwitchExportOn();
   if ($Stage == stCall) {
    if ($EXPORT == "Russian") {
?> Определим модель <?php echo $this->ID; ?>.<?php
    } else if ($EXPORT == "XML") {
      $n = GetNextMail("COUNTER");
      ExportXMLElement($n++, "clsE_SModel", "ID$n", array("Name"=>$this->ID));
      PutMail("COUNTER", $n);
    }
   } else if ($Stage == stResource && $EXPORT == "XML") {
      $n = GetNextMail("OBJS");
      PutMail("OBJS", $n+1);
   }
   PutMail("EXPORT",$EXPORT);
   return;
}

switch ($Stage) {
  case stResource:
?>#ifndef __SPECIFIC__
#define __SPECIFIC__

#include "cfgfile.h"
#include "area3d.h"
#include "kinetic.h"
#include "solvers.h"

<?php  break;
}

cortege_push($Control["Phase"],"NOTHING");

?>
