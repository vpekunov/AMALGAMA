<?
  $OutName = "\$" . $this->ID . "_Out";
  if ($Stage == stResource) {
     global $DATA;
     global $COLS;
     global $ROWS;

     if ($this->Normalize == "Yes") {
        echo "Данные столбца " . $this->Num . " нормализуются.\n";

        $Min = 1E300;
        $Max = -1E300;
        
        for ($i = 0; $i < $ROWS; $i++) {
            if ($Min > $DATA[$i][$this->Num]) $Min = $DATA[$i][$this->Num];
            if ($Max < $DATA[$i][$this->Num]) $Max = $DATA[$i][$this->Num];
        }

        if ($this->ClassID == "clsNNetInput") {
           $Num = GetNextMail("NI");
           if ($Num === "")
              $Num = 0;
           PutMail("NI", $Num + 1);
           PutMail("MIN" . $this->NNum, $Min);
           PutMail("MAX" . $this->NNum, $Max);
        } elseif ($this->ClassID == "clsNNetOutput") {
           PutMail("MINY", $Min);
           PutMail("MAXY", $Max);
        }

        echo "  Min = $Min. Max = $Max.";
        if ($Min == $Max) {
           echo " Нормализовано к [0 .. 0]\n";
           for ($i = 0; $i < $ROWS; $i++)
               $DATA[$i][$this->Num] = 0.0;
        } else {
           echo " Нормализовано к [-1 .. +1]\n";
           for ($i = 0; $i < $ROWS; $i++)
               $DATA[$i][$this->Num] = 2.0*($DATA[$i][$this->Num] - $Min)/($Max - $Min) - 1.0;
        }
     } else
        echo "Данные столбца " . $this->Num . " не нормализуются.\n";

     AppendTapeEnd($OutName . " = \$DATA[\$nPair][" . $this->Num . "];\n");
  }
?>