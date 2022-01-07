<?
  if (!$this->Passed && !empty($Barrier["Calculated"]))
     {
      $this->Passed = true;
      for ($i=0; $i<$powBarrier && $this->Passed; $i++)
        $this->Passed = $Barrier["Calculated"][$i];
      if ($this->Passed)
         {
          asort($Barrier["R2Norm"],SORT_NUMERIC);
          $IDs = array();
          foreach ($Barrier["R2Norm"] as $Key => $Val)
            array_push($IDs,$Barrier["_ID"][$Key]);
          $Count = count($Barrier["R2Norm"]);
          while ($Count-- && ($Item = array_shift($Barrier["R2Norm"]))=="")
             array_shift($IDs);
          if ($Item!="") array_unshift($Barrier["R2Norm"],$Item);
          $N = floor($this->Percent*0.01*count($Barrier["R2Norm"])+0.5);
          $Keys = array_keys($Barrier["R2Norm"]);
          echo "Barrier($this->ID). Selected: [";
          for ($i=0; $i<$N; $i++)
              {
               PutMail("Allowed",$IDs[$Keys[$i]]);
               echo $IDs[$Keys[$i]],$i==$N-1 ? "" : ",";
              }
          echo "]\n";
          // Active on next Event
          PutMail(nonempty_value($Barrier["Event"]),array(array($this->ID),0));
         }
     }
?>