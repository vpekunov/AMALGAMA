<?
  global $nLayers;
  global $nPair;
  global $err;
  global $last_err;
  global $epochs;
  global $ROWS;
  global $COLS;

  $PlanNext = false;
  if ($Stage == stResource) {
     $nLayers = $Inp["LayerNum"][0] + 1;
  } elseif ($Stage == stInit) {
     $this->TapeF = GetTape();
     ClearTape();
  } elseif ($Stage == stCall) {
     $this->TapeB = GetTape();
     ClearTape();
     $err = 0;
     $epochs = 0;
     $nPair = 0;
     $PlanNext = true;
  } elseif ($Stage == stDone) {
?>
Конфигурация сети
-----------------------------------------------------
<?
     $NI = GetNextMail("NI");
     echo $NI, "\n\n"; // Number of inputs
     // Inputs-output file
     $F = GetNextMail("FILE");
     echo $F, "\n\n";
     // Total numbers of rows and cols
     echo $ROWS, " ", $COLS, "\n\n";
     // Numbers of columns: X0 X1 ... Y
     for ($i = 0; $i < $NI; $i++) {
         $ICOL = GetNextMail("X" . $i);
         echo $ICOL, " ";
     }
     $OCOL = $Out["OutNum"][0];
     echo $OCOL, "\n\n";
     // Number of neurons
     $N = array();
     for ($i = 0; $i < $nLayers; $i++) {
         $N[$i] = GetNextMail("N" . $i);
         echo $N[$i], " ";
     }
     echo "\n\n";
     // Last Err
     echo $last_err, "\n\n";
     // Mins of inputs
     for ($i = 0; $i < $NI; $i++)
         echo GetNextMail("MIN" . $i), " ";
     echo "\n";
     // Maxs of inputs
     for ($i = 0; $i < $NI; $i++)
         echo GetNextMail("MAX" . $i), " ";
     echo "\n\n";
     // New Mins of inputs
     for ($i = 0; $i < $NI; $i++)
         echo "-1 ";
     echo "\n";
     // New Maxs of inputs
     for ($i = 0; $i < $NI; $i++)
         echo "1 ";
     echo "\n\n";
     // Min & Max of output
     echo GetNextMail("MINY"), "\n";
     echo GetNextMail("MAXY"), "\n\n";
     // New Min & Max of output
     echo "-1\n1\n\n";
     // W by layers. Each W is [neurons of this layer, inputs of this layer]
     $PrevNum = $NI;
     for ($i = 0; $i < $nLayers; $i++) {
         $ThisNum = $N[$i];
         for ($j = 0; $j < $PrevNum; $j++) {
             for ($k = 0; $k < $ThisNum; $k++) {
                 $V = GetNextMail("W" . $i . $j . $k);
                 if ($V === "") $V = 0.0;
                 echo $V, " ";
             }
             echo "\n";
         }
         echo "\n";
         $PrevNum = $ThisNum;
     }
     // B by layers. Each B is [neurons of this layer]
     for ($i = 0; $i < $nLayers; $i++) {
         $ThisNum = $N[$i];
         for ($k = 0; $k < $ThisNum; $k++) {
             $V = GetNextMail("B" . $i . $k);
             if ($V === "") $V = 0.0;
             echo $V, " ";
         }
         echo "\n\n";
     }
?>
-----------------------------------------------------
Финальная лента системы (финальный оператор эволюции)
-----------------------------------------------------
<?
     echo GetTape();
?>
-----------------------------------------------------
<?
     PlanAutoStart("nnets_simplify");
  } else {
     $nPair++;
     if ($nPair == $ROWS) {
        echo "Q(w,b) = ", $err, "\n";
        $epochs++;
        $nPair = 0;
        $last_err = $err;
        $err = 0.0;
     }
     if ($epochs < $this->nEpochs)
        $PlanNext = true;
  }

  if ($PlanNext) {
     CreateEventAfter($Stage, __LINE__);
     ClearTape();
     AppendTapeEnd("global \$nPair;\n");
     AppendTapeEnd("\$nPair = " . $nPair . ";\n");
     AppendTapeEnd("global \$alpha;\n");
     AppendTapeEnd("\$alpha = " . $this->alpha . ";\n");
     AppendTapeEnd("global \$nu;\n");
     AppendTapeEnd("\$nu = " . $this->nu . ";\n");
     AppendTapeEnd("global \$err;\n");
     AppendTapeEnd($this->TapeF);
     AppendTapeEnd("\$delta = " . $Inp["OutName"][0] . " - " . $Out["OutName"][0] . ";\n");
     AppendTapeEnd("\$err += abs(\$delta);\n");
     AppendTapeEnd($this->TapeB);
  }
?>