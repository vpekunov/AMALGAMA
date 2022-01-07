<?
  if ($Stage!=stResource)
     {
      AnalyzeInput($powX1,$X1);
      AnalyzeInput($powX2,$X2);
     }
  
  switch ($Stage) {
    case stResource:
      $this->MLab = $X1["MatLab"][0];
      $this->MLabDir = $X1["MatLabDir"][0];
      cortege_push($Val["MatLab"],$this->MLab);
      cortege_push($Val["MatLabDir"],$this->MLabDir);
      CollectBinaryIDs($powX1,$X1["IDs"],$powX2,$X2["IDs"],$IDs1,$IDs2);
      array_push($IDs1,$this->ID);
      cortege_push($Val["IDs"],array_unique(array_merge($IDs1,$IDs2)));
      CollectBinaryIDs($powX1,$X1["allIDs"],$powX2,$X2["allIDs"],$allIDs1,$allIDs2);
      array_push($allIDs1,$this->ID);
      cortege_push($Val["allIDs"],array_unique(array_merge($allIDs1,$allIDs2)));
      break;
    case stDone:
      $Expression = $this->Function;
      for ($i=1; $i<=count($this->K); $i++)
          $Expression = str_replace("K($i)","(".$this->K[$i-1].")",$Expression);
      echo $this->ID." = inline('".$Expression."','X1','X2');\n";
      $Expression = $this->ID."(#1,#2)";
      if (isset($this->Selected[0]))
         $Expression = str_replace("#1","(".$X1["Function"][$this->Selected[0]].")",$Expression);
      if (isset($this->Selected[1]))
         $Expression = str_replace("#2","(".$X2["Function"][$this->Selected[1]].")",$Expression);
      cortege_push($Val["Function"],$Expression);

      $CanSpeak = $powBarrier==0 || !$this->Stopped;
      cortege_push($Val["R2Norm"],$CanSpeak ? $this->R2Norm : 1E30);
      break;
    default:
      CollectBinaryIDs($powX1,$X1["IDs"],$powX2,$X2["IDs"],$IDs1,$IDs2);
      CollectBinaryIDs($powX1,$X1["allIDs"],$powX2,$X2["allIDs"],$allIDs1,$allIDs2);

      if ($this->Initialization=="")
         while ($Mail = ReadNextMail($this->ID,"Initialization"))
           $this->Initialization .= $Mail;

      $Activated = CheckActive($this->ID,$Out);
      if ($this->State=="")
         $this->Fix = ReadNextMail($this->ID,"SHIFT".$Stage);
      if ($Out!="")
         $this->Goal = $Out;

      $SendCalc = 0;
      if (($Activated || (nonempty_value($X1["Changed"]) || nonempty_value($X2["Changed"]))) && !empty_array($X1["Value"]) && !empty_array($X2["Value"]))
         {
          $this->Selected =
            SelectBestVariant(
              $this->ID, $this->Function, $this->Init, array(),
              $this->Initialization,
              array($powX1,$powX2),
              $this->Goal,
              array($X1["Value"],$X2["Value"]),array($X1["R2Norm"],$X2["R2Norm"]),
              array($X1["Init"],$X2["Init"]),
              $this->MLab,$this->MLabDir,$this->MLabFuns,
              $this->NP,$this->Rad,
              $this->R2Norm,$this->K,$this->Res
            );

          echo $this->Fix."$this->ID[$this->Function] has Goal(".(strlen($this->Goal)>200 ? substr($this->Goal,0,200)."...]" : $this->Goal).") with K=[".implode(",",$this->K)."] and R2Norm = ".$this->R2Norm."\n";

          $Inp1 = $X1["Value"][$this->Selected[0]];
          $R21  = $X1["R2Norm"][$this->Selected[0]];
          $Inp2 = $X2["Value"][$this->Selected[1]];
          $R22  = $X2["R2Norm"][$this->Selected[1]];

          $Inp = "";

          if (GetNextMail("RECALC_".$this->ID)!="")
             $this->Recalc = true;

          if ($this->VarX=="X1" || $this->VarX=="Best" && $R21>$R22)
             {
              $RevFun = $this->RevF1;
              $Inp = "X2=".$Inp2;
              $ToPlan = array($IDs1);
              $ToPlanAll = $allIDs1;
             }
          elseif ($this->VarX=="X2" || $this->VarX=="Best" && $R21<=$R22)
             {
              $RevFun = $this->RevF2;
              $Inp = "X1=".$Inp1;
              $ToPlan = array($IDs2);
              $ToPlanAll = $allIDs2;
             }

          if ($Inp && !empty($ToPlan))
             if ($this->State==="" && $this->Recalc)
                {
                 $this->State = "FIX";
                 echo com_invoke($this->MLab,"Execute",
                     $this->Initialization.
                     $Inp.";".
                     "Y=".$this->Goal.";".
                     "Result=($RevFun);".
                     "save -ASCII -DOUBLE '$this->MLabDir\\$this->ID.res' Result;");
                 $ToPlan[1] = "[".implode(" ",GetVector($this->MLabDir."\\".$this->ID.".res",5000))."]";
                 $this->Stack = array();
                 array_push($this->Stack,$this->R2Norm);
                 echo $this->Fix."... fix ".(strlen($Inp)>200 ? substr($Inp,0,200)."...]" : $Inp).". Plan to enhance in [".implode(",",$ToPlan[0])."] \n";
                 $this->R2Norm = 1E30;
                 unset($this->Res);
                 $this->Recalc = false;
                }
             else if ($this->State=="FIX")
                {
                 $SavedR2Norm = array_pop($this->Stack);
                 if ($this->R2Norm<$SavedR2Norm)
                    {
                     $this->State = "";
                     $this->Stack = array();
                     echo $this->Fix."... R2Norm successfully enhanced.\n";
                     $this->Fix = "";
                    }
                 else
                    {
                     $this->State  = "RESTORE";
                     $this->R2Norm = 1E30;
                     unset($this->Res);
                     $ToPlan[1] = $this->Goal;
                     echo $this->Fix."... can't enhance R2Norm. Backtracking to $SavedR2Norm... \n";
                    }
                }
             else if ($this->State=="RESTORE")
                {
                 $this->State = "";
                 $this->Stack = array();
                 $this->Fix   = "";
                }
          
          $SendCalc = $this->State==="";
          if (!$SendCalc)
             {
              PutMail("SHIFT".nonempty_value($X1["Event"]),$this->Fix.($this->State=="FIX" ? "  " : ""));
              $NewEvent = nonempty_value($X1["Event"]);
              PutMail($NewEvent,$ToPlan);
              if (isset($ToPlanAll))
                 foreach ($ToPlanAll as $V)
                   {
                    if (GetNextMail("RECALC_".$V)=="")
                       PutMail("RECALC_".$V,1);
                    PutMail("Goal_".$V,$ToPlan[1]);
                   }
             }
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
      cortege_push($Val["IDs"],!$powBarrier ? array_unique(array_merge($IDs1,$IDs2)) : array());
      cortege_push($Val["allIDs"],!$powBarrier ? array_unique(array_merge($allIDs1,$allIDs2,array($this->ID))) : array());
      cortege_push($Val["Event"],nonempty_value($X1["Event"]));
      cortege_push($Barrier["Event"],nonempty_value($X1["Event"]));
      cortege_push($Val["Value"],$CanSpeak ? $this->Res : "");
      cortege_push($Val["R2Norm"],$CanSpeak ? $this->R2Norm : 1E30);
      $Val["Init"] = $X1["Init"];
      foreach ($X2["Init"] as $V)
        cortege_push($Val["Init"],$V);
      if (isset($this->Res) && $this->Res!=="")
         {
          cortege_push($Barrier["Calculated"],1);
          cortege_push($Val["Calculated"],1);
         }
      cortege_push($Barrier["R2Norm"],$this->R2Norm);
  }
?>