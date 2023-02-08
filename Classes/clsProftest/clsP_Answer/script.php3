<?php
cortege_push($Quest,$this->ID);
switch ($Stage) {
  case stResource:
    echo "Answer(".$this->ID.",".$this->MaxAnswers.")\n";
    echo $this->Descriptor;
    echo "EndA\n\n";
    break;
}
?>