<?
  if ($Stage == stResource) {
     global $DATA;
     global $COLS;
     global $ROWS;

     $DATA = array();

     $F = fopen($this->File, "r");
     if ($F) {
        if (feof($F))
           MakeError("Data Error : ", "Data file is empty", __LINE__);
        else {
          $S = fgets($F);
          $Delimiter = strchr($S, "\t") ? "\t" : " ";

          $_DATA = array();
          $_DATA[0] = explode($Delimiter, $S);

          $COLS = count($_DATA[0]);
          $ROWS = 1;

          $_IDXS = array();
          array_push($_IDXS, 0);
          while (!feof($F)) {
            $Line = fgets($F);
            if ($Line != "") {
               $_DATA[$ROWS] = explode($Delimiter, $Line);
               if ($COLS != count($_DATA[$ROWS]))
                  MakeError("Data Error : ", "Incorrect number of rows [".($ROWS+1)." line]", __LINE__);
               array_push($_IDXS, $ROWS);
               $ROWS++;
            }
          }
          $L = $ROWS;
          while ($L > 0) {
            $idx = rand() % $L;
            array_push($DATA, $_DATA[$idx]);
            array_splice($_DATA, $idx, 1);
            $L--;
          }
        }
        fclose($F);
        AppendTapeEnd("global \$DATA;\n");
        AppendTapeEnd("global \$ROWS;\n");
        AppendTapeEnd("global \$COLS;\n");
     } else
        MakeError("Data Error : ", "Can't open the Data file", __LINE__);
  } elseif ($Stage == stDone) {
     PutMail("FILE", $this->File);
  }
?>