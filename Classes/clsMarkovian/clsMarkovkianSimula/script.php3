<?php
define(EPS, 1E-15);

if ($Stage == stResource) {
} elseif ($Stage==stInit) {
    $VARS = array();
    $IN = array();
    do {
        $P = GetNextMail("INStructure");
        if ($P !== "") {
           array_push($IN, $P);
           echo "IN: ", $P["From"], " ", $P["To"], "\n";
           $VARS[$P["To"]] = true;
        }
    } while ($P !== "");
    echo "\n";

    $OUT = array();
    do {
        $X = GetNextMail("OUTStructure");
        if ($X !== "") {
           array_push($OUT, $X);
           echo "OUT: ", $X["From"], " ", $X["To"], "\n";
           $VARS[$X["From"]] = true;
        }
    } while ($X !== "");
    echo "\n";

    $this->VarNames = array_keys($VARS);
    echo "Collected vars: ".implode($this->VarNames, " ")."\n";

    $MATRIX = array();
    foreach ($this->VarNames as $Val) {
      $MATRIX[$Val] = array();
      foreach ($this->VarNames as $_Val)
         $MATRIX[$Val][$_Val] = 0;
    }
    foreach ($OUT as $Val) {
       $NodeName = $Val["From"];
       $Node2Name = "";
       $WeightName = $Val["To"];
       foreach ($IN as $_Val)
         if ($_Val["From"] == $WeightName) {
            $Node2Name = $_Val["To"];
            break;
         }
       $MATRIX[$NodeName][$Node2Name] = GetNextMail($WeightName);
    }

    $N = count($this->VarNames);
    $this->Matrix = array();
    $i = 0;
    foreach ($MATRIX as $Val)
        $this->Matrix[$i++] = array_values($Val);

    echo "== Matrix ==\n";
    for ($i = 0; $i < $N; $i++)
       echo implode($this->Matrix[$i], " "), "\n";
    echo "============\n";
    CreateEventAfter(stInit, __LINE__);
} elseif ($Stage == stCall) {
    echo "== Results ==\n";
    foreach ($this->VarNames as $Val)
       echo $Val." : ".GetNextMail($Val), "\n";
} elseif ($Stage == stDone) {
} else {
    $P = array();
    foreach ($this->VarNames as $Val)
       array_push($P, GetNextMail($Val));
    $P1 = array();
    $N = count($this->VarNames);
    $delta = 0.0;
    for ($i = 0; $i < $N; $i++) {
        $P1[$i] = 0.0;
        for ($j = 0; $j < $N; $j++)
            $P1[$i] += $P[$j]*$this->Matrix[$j][$i];
        PutMail($this->VarNames[$i], $P1[$i]);
        $delta += abs($P1[$i]-$P[$i]);
    }
    if ($delta > EPS)
       CreateEventAfter($Stage, __LINE__);
}
?>