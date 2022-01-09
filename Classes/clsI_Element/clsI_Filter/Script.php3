<?
  GetNextMail("COUNT_".$this->ID);
  PutMail("COUNT_".$this->ID,0);

  switch ($Stage) {
    case stResource:
      $this->MLab = $Barrier["MatLab"][0];
      $this->MLabDir = $Barrier["MatLabDir"][0];
      cortege_push($Val["MatLab"],$this->MLab);
      cortege_push($Val["MatLabDir"],$this->MLabDir);
      $IDs = CollectUnaryIDs($this->ID,$powBarrier,$Barrier["IDs"]);
      cortege_push($Val["IDs"],array_unique($IDs));
      $allIDs = CollectUnaryIDs($this->ID,$powBarrier,$Barrier["allIDs"]);
      cortege_push($Val["allIDs"],array_unique($allIDs));
      break;
    default:
      $DoneStage = $this->MustBeFixed=="No" && $Stage==stDone;
      if ($DoneStage || !$this->Passed && !empty($Barrier["Calculated"]))
         {
          $this->Passed = true;
          if (!$DoneStage)
             for ($i=0; $i<$powBarrier && $this->Passed; $i++)
               $this->Passed = $Barrier["Calculated"][$i];
          $this->Selected = array();
          if ($this->Passed)
             {
              $Norms  = $Barrier["R2Norm"];
              $Idents = $Barrier["_ID"];
              asort($Norms,SORT_NUMERIC);
              $IDs = array();
              foreach ($Norms as $Key => $V)
                array_push($IDs,$Idents[$Key]);
              $Count = count($Norms);
              while ($Count-- && ($Item = array_shift($Norms))=="")
                 array_shift($IDs);
              if ($Item!="") array_unshift($Norms,$Item);
              $N = min($powVal,count($Norms));
              $Keys = array_keys($Norms);
              for ($i=0; $i<$N; $i++)
                  $this->Selected[] = $IDs[$Keys[$i]];
              if ($Stage!=stDone)
                 {
                  echo "Filter($this->ID). Selected: [";
                  for ($i=0; $i<$N; $i++)
                      echo $this->Selected[$i],$i==$N-1 ? "" : ",";
                  echo "]\n";
                 }
              $Changed = true;
             }
         }
      if ($this->Passed)
         {
          if ($Stage!=stDone) $Val["Event"] = $Barrier["Event"];
          $N = empty($this->Selected) ? 0 : count($this->Selected);
          // Выдаем столько значений, сколько есть, максимум -- сколько выходов.
          for ($i=0; $i<$N; $i++)
            {
             $Idx = array_search($this->Selected[$i],$Barrier["_ID"]);
             cortege_push($Val["R2Norm"],$Barrier["R2Norm"][$Idx]);
             if ($Stage==stDone)
                cortege_push($Val["Function"],$Barrier["Function"][$Idx]);
             else
                {
                 cortege_push($Val["Value"],$Barrier["Value"][$Idx]);
                 cortege_push($Val["Init"],$Barrier["Init"][$Idx]);
                 cortege_push($Val["Calculated"],1);
                 cortege_push($Val["Changed"],$Changed);
                }
            }
          if ($this->MustBeFixed=="No")
             {
              $IDs = CollectUnaryIDs($this->ID,$powBarrier,$Barrier["IDs"]);
              cortege_push($Val["IDs"],array_unique($IDs));
              $allIDs = CollectUnaryIDs($this->ID,$powBarrier,$Barrier["allIDs"]);
              cortege_push($Val["allIDs"],array_unique($allIDs));
              $this->Passed = false;
             }
         }
      else
         $N = 0;
      for ($i=$N; $i<$powVal; $i++)
        {
         cortege_push($Val["R2Norm"],1E30);
         if ($Stage==stDone)
            cortege_push($Val["Function"],"");
         else
            {
             cortege_push($Val["Value"],"");
             cortege_push($Val["Init"],"");
             cortege_push($Val["Calculated"],0);
             cortege_push($Val["Changed"],0);
            }
        }
  }
?>