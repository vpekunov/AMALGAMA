<?php
if ($Stage==stCall)
   {
    $Qarray   = explode(",",$this->QList);
    $NQuestions =  _count($Qarray);
    $Aarray   = explode(",",$this->Answers);
    $NAnswers =  _count($Aarray);
    $Sarray   = explode(",",$this->Scores);
    $NScores  =  _count($Sarray);
    $Questions = "&".implode(",&",$Qarray);
    if ($this->Scheme=="1=>1")
       {
        if ($NScores!=$NQuestions && $NScores!=1)
           MakeError("Model Error"," ".$this->ID.": Number of answers can be equal to 1 or number of questions only",__LINE__);
       }
    else
       {
        if ($NAnswers!=$NScores)
           MakeError("Model Error"," ".$this->ID.": Number of answers must be equal to number of scores",__LINE__);
       }
    if ($NScores==1 && $NAnswers==1)
       echo "  Define ".$this->ID.":Number = ".$Sarray[0]."*Test(".$Aarray[0].",".$Questions.")\n\n";
    else
      if ($this->Scheme=="1=>1")
         {
          $vPrefix = $this->ID."[c".$this->ID."]";
          echo "  Define q".$this->ID.":Array[1:".$NQuestions."] = {".$Questions."}\n";
          if ($NAnswers>1)
             echo "  Define a".$this->ID.":Array[1:".$NAnswers."] = {".$this->Answers."}\n";
          if ($NScores>1)
             echo "  Define s".$this->ID.":Array[1:".$NScores."] = {".$this->Scores."}\n";
          echo "  Define ".$this->ID.":Number = 0\n";
          echo "  Define c".$this->ID.":Number = 1\n";
          echo "  While (c".$this->ID."<=".$NQuestions.")\n";
          echo "    If q".$vPrefix."=".($NAnswers==1 ? $Aarray[0] : "a".$vPrefix)."\n";
          echo "       ".$this->ID." := ".$this->ID."+".($NScores==1 ? $Sarray[0] : "s".$vPrefix)."\n";
          echo "    EndIf\n";
          echo "    c".$this->ID.":=c".$this->ID."+1\n";
          echo "  EndW\n\n";
         }
      else
         {
          $vPrefix  = $this->ID."[c".$this->ID."]";
          $vPrefix1 = $this->ID."[c".$this->ID."1]";
          echo "  Define q".$this->ID.":Array[1:".$NQuestions."] = {".$Questions."}\n";
          if ($NAnswers>1)
             echo "  Define a".$this->ID.":Array[1:".$NAnswers."] = {".$this->Answers."}\n";
          if ($NScores>1)
             echo "  Define s".$this->ID.":Array[1:".$NScores."] = {".$this->Scores."}\n";
          echo "  Define ".$this->ID.":Number = 0\n";
          echo "  Define c".$this->ID."1:Number\n";
          echo "  Define c".$this->ID.":Number = 1\n";
          echo "  While (c".$this->ID."<=".$NQuestions.")\n";
          echo "    c".$this->ID."1:=1\n";
          echo "    While (c".$this->ID."1<=".$NAnswers.")\n";
          echo "      If q".$vPrefix."=a".$vPrefix1."\n";
          echo "         ".$this->ID." := ".$this->ID."+".($NScores==1 ? $Sarray[0] : "s".$vPrefix1)."\n";
          echo "      EndIf\n";
          echo "      c".$this->ID."1:=c".$this->ID."1+1\n";
          echo "    EndW\n";
          echo "    c".$this->ID.":=c".$this->ID."+1\n";
          echo "  EndW\n\n";
         }
   }
cortege_push($Out["Name"],$this->Name);
?>