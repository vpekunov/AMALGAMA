<?php
  global $nLayers;

  $OutName = "\$" . $this->ID . "_Out";
  $OName = "\$" . $this->ID . "_Y";

  if ($Inp["_ClassID"][0] == "clsNNetInput")
     $LayerNum = 0;
  else
     $LayerNum = $Inp["LayerNum"][0] + 1;

  $BName  = "\$" . $this->ID . "_B";
  $DBName = "\$" . $this->ID . "_DB";
  $WName  = "\$" . $this->ID . "_W";
  $DWName = "\$" . $this->ID . "_DW";

  $Vars =  "global " . $BName . ";\n";
  $Vars .= "global " . $WName . ";\n";
  $Vars .= "global " . $DBName . ";\n";
  $Vars .= "global " . $DWName . ";\n";

  eval($Vars);

  if ($Stage == stInit) {
     $Init =  $BName . " = mt_rand()/mt_getrandmax();\n";
     $Init .= $DBName . " = 0.0;\n";
     $Init .= $WName . " = array();\n";
     $Init .= $DWName . " = array();\n";
     for ($i = 0; $i < count($Inp["OutNum"]); $i++) {
         $Init .= $WName . "[" . $Inp["OutNum"][$i] . "] = mt_rand()/mt_getrandmax();\n";
         $Init .= $DWName . "[" . $Inp["OutNum"][$i] . "] = 0.0;\n";
     }
     eval($Init);

     $F = array();
     for ($i = 0; $i < count($Inp["OutNum"]); $i++)
         array_push($F, $Inp["OutName"][$i] . "*" . $WName . "[" . $Inp["OutNum"][$i] . "]");

     $Calc =  $OName . " = " . $BName . " + " . implode(" + ", $F) . ";\n";
     if ($LayerNum == $nLayers - 1)
        $Calc .= $OutName . " = " . $OName . ";\n";
     else {
        $Calc .= $OutName . " = 1.0/(1.0+exp(-" . $OName . "));\n";
        $Calc .= "\$" . $this->ID . "_delta = 0.0;\n";
     }

     AppendTapeEnd($Vars . $Calc);
  } elseif ($Stage == stCall) {
     if ($LayerNum == $nLayers - 1) {
        // Deltas
        if ($LayerNum > 0) {
            for ($k = 0; $k < count($Inp["OutNum"]); $k++) {
                AppendTapeBegin("\$" . $Inp["_ID"][$k] . "_delta += " .
                   $Inp["OutName"][$k] . "*(1.0 - " . $Inp["OutName"][$k] . ")*\$delta*" .
                   $WName . "[" . $Inp["OutNum"][$k] . "];\n");
            }
        }
        // WB-calculations
        for ($k = 0; $k < count($Inp["OutNum"]); $k++) {
            AppendTapeBegin($WName . "[" . $Inp["OutNum"][$k] . "] += " . $DWName . "[" . $Inp["OutNum"][$k] . "];\n");
            AppendTapeBegin($DWName . "[" . $Inp["OutNum"][$k] . "] = " .
               "\$alpha*" . $DWName . "[" . $Inp["OutNum"][$k] . "] + " .
               "(1 - \$alpha)*(-\$nu*\$delta*" . $Inp["OutName"][$k] . ");\n");
        }
        AppendTapeBegin($BName . " += " . $DBName . ";\n");
        AppendTapeBegin($DBName . " = \$alpha*" . $DBName . " + (1 - \$alpha)*(-\$nu*\$delta);\n");
     } else {
        // Deltas
        if ($LayerNum > 1) {
            for ($j = 0; $j < count($Inp["OutNum"]); $j++) {
                AppendTapeBegin("\$" . $Inp["_ID"][$j] . "_delta += " .
                   $Inp["OutName"][$j] . "*(1.0 - " . $Inp["OutName"][$j] . ")*\$" . $this->ID. "_delta*" .
                   $WName . "[" . $Inp["OutNum"][$j] . "];\n");
            }
        }
        // WB-calculations
        for ($k = 0; $k < count($Inp["OutNum"]); $k++) {
            AppendTapeBegin($WName . "[" . $Inp["OutNum"][$k] . "] += " . $DWName . "[" . $Inp["OutNum"][$k] . "];\n");
            AppendTapeBegin($DWName . "[" . $Inp["OutNum"][$k] . "] = " .
               "\$alpha*" . $DWName . "[" . $Inp["OutNum"][$k] . "] + " .
               "(1 - \$alpha)*(-\$nu*\$" . $this->ID . "_delta*" . $Inp["OutName"][$k] . ");\n");
        }
        AppendTapeBegin($BName . " += " . $DBName . ";\n");
        AppendTapeBegin($DBName . " = \$alpha*" . $DBName . " + (1 - \$alpha)*(-\$nu*\$" . $this->ID . "_delta);\n");
     }
  } elseif ($Stage == stDone) {
     $Num = GetNextMail("N" . $LayerNum);
     if ($Num === "")
        $Num = 0;
     PutMail("N" . $LayerNum, $Num + 1);

     PutMail("B" . $LayerNum . $this->Num, eval("return " . $BName . ";"));

     for ($i = 0; $i < count($Inp["OutNum"]); $i++)
         PutMail("W" . $LayerNum . $Inp["OutNum"][$i] . $this->Num,
                 eval("return " . $WName . "[" . $Inp["OutNum"][$i] . "];"));
  }

  cortege_push($Out["OutName"], $OutName);
  cortege_push($Out["OutNum"], $this->Num);
  cortege_push($Out["LayerNum"], $LayerNum);
?>