<?
switch ($Stage) {
  case stResource:
    echo "Text(".$this->ID.")\n";
    echo $this->Descriptor;
    echo "EndT\n\n";
    break;
}
cortege_push($Map,$this->ID);
?>