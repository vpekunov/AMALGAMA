<?
  if ($Stage!=stResource) AnalyzeInput($powX,$X);

  switch ($Stage) {
    case stResource:
      $this->MLab = $X["MatLab"][0];
      $this->MLabDir = $X["MatLabDir"][0];
      cortege_push($Val["MatLab"],$this->MLab);
      cortege_push($Val["MatLabDir"],$this->MLabDir);
      $IDs = CollectUnaryIDs($this->ID,$powX,$X["IDs"]);
      cortege_push($Val["IDs"],array_unique($IDs));
      $allIDs = CollectUnaryIDs($this->ID,$powX,$X["allIDs"]);
      cortege_push($Val["allIDs"],array_unique($allIDs));
      break;
    case stDone:
      if ($this->Init=="multinetwork")
         {
          $Expression = $this->ID."(";
          for ($i=1, $XX="[", $Args=""; $i<=$powX; $i++)
            {
             $XX         .= "X".$i.($i!=$powX ? ";" : "");
             $Expression .= $X["Function"][$i-1].($i!=$powX ? "," : "");
             $Args       .= "'X".$i.($i!=$powX ? "'," : "'");
            }
          $XX         .= "]";
          $Expression .= ")";
          echo $this->ID." = inline('sim(getfield(load(''".$this->K."''),''BestK''),$XX)',$Args);\n";
          cortege_push($Val["Function"],$Expression);
         }
      else
         {
          if ($this->Init=="network")
             echo $this->ID." = inline('sim(getfield(load(''".$this->K."''),''BestK''),X)','X');\n";
          else if ($this->Init=="polynom")
             echo $this->ID." = inline('polyval([".implode(",",$this->K)."],X)','X');\n";
          else
             {
              $Expression = $this->Function;
              for ($i=1; $i<=count($this->K); $i++)
                  $Expression = str_replace("K($i)","(".$this->K[$i-1].")",$Expression);
              echo $this->ID." = inline('".$Expression."','X');\n";
             }
          $Expression = $this->ID."(#)";
          if (isset($this->Selected))
             cortege_push($Val["Function"],
                str_replace("#","(".$X["Function"][$this->Selected].")",$Expression)
             );
         }

      $CanSpeak = $powBarrier==0 || !$this->Stopped;
      cortege_push($Val["R2Norm"],$CanSpeak ? $this->R2Norm : 1E30);
      break;
    default:
      if ($this->Initialization=="")
         while ($Mail = ReadNextMail($this->ID,"Initialization"))
           $this->Initialization .= $Mail;
      $Activated  = CheckActive($this->ID,$NewGoal);
      $Fix        = ReadNextMail($this->ID,"SHIFT".$Stage);
      if ($NewGoal!="")
         $this->Goal = $NewGoal;
      $SendCalc  = (nonempty_value($X["Changed"]) || $Activated) && !empty_array($X["Value"]);
      if ($SendCalc)
         {
          $this->Selected =
            SelectBestVariant(
              $this->ID, $this->Function, $this->Init, $this->Parameters,
              $this->Initialization,
              array($powX),$this->Goal,array($X["Value"]),array($X["R2Norm"]),
              array($X["Init"]),
              $this->MLab,$this->MLabDir,$this->MLabFuns,
              $this->NP,$this->Rad,
              $this->R2Norm,$this->K,$this->Res
            );
          $this->Selected = $this->Selected[0];
          echo $Fix.$this->ID."[$this->Function] with Goal(".(strlen($this->Goal)>200 ? substr($this->Goal,0,200)."...]" : $this->Goal).") gives K=[".(is_array($this->K) ? implode(",",$this->K) : $this->K)."] with R2Norm = ".$this->R2Norm."\n";
         }
      if ($powBarrier)
         while ($this->Stopped && ($Mail = ReadNextMail($this->ID,"Allowed")))
           if ($this->ID==$Mail)
              {
               $this->Stopped = false;
               $SendCalc = 1;
              }
      $CanSpeak = $powBarrier==0 || !$this->Stopped;
      cortege_push($Val["Changed"],$SendCalc && $CanSpeak);
      if ($powBarrier)
         {
          $IDs = array();
          $allIDs = array();
         }
      else
         {
          $IDs = CollectUnaryIDs($this->ID,$powX,$X["IDs"]);
          $allIDs = CollectUnaryIDs($this->ID,$powX,$X["allIDs"]);
         }
      cortege_push($Val["IDs"],array_unique($IDs));
      cortege_push($Val["allIDs"],array_unique($allIDs));
      cortege_push($Val["Event"],nonempty_value($X["Event"]));
      cortege_push($Barrier["Event"],nonempty_value($X["Event"]));
      cortege_push($Val["Value"],$CanSpeak ? $this->Res : "");
      cortege_push($Val["R2Norm"],$CanSpeak ? $this->R2Norm : 1E30);
      $Val["Init"] = $X["Init"];
      if (isset($this->Res) && $this->Res!=="")
         {
          cortege_push($Barrier["Calculated"],1);
          cortege_push($Val["Calculated"],1);
         }
      cortege_push($Barrier["R2Norm"],$this->R2Norm);
  }
?>