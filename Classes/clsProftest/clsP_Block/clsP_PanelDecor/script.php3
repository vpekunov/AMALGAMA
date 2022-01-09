<?
if ($Stage==$this->Event)
   {
    $Panel = "ob".$this->Panel."Panel";
    echo $this->Prefix."Size(".$Panel.",".$this->Left.",".$this->Top.",".$this->Width.",".$this->Height.")\n";
    echo $this->Prefix."Font(".$Panel.",'".$this->FontName."',".$this->FontSize.",".$this->FontColor.",".
         ($this->Bold=="Yes" ? 1 : 0).",".
         ($this->Italic=="Yes" ? 1 : 0).",".
         ($this->Underline=="Yes" ? 1 : 0).")\n";
    echo $this->Prefix."Color(".$Panel.",".$this->Color.")\n";
   }
?>