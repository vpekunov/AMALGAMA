<?
  if ($Stage!=stResource) AnalyzeInput($powY,$Y);

  switch ($Stage) {
    case stResource:
      $this->MLab = $Y["MatLab"][0];
      $this->MLabDir = $Y["MatLabDir"][0];
      if ((ReadNextMail($this->ID,"MatLABreferenced"))=="")
         PutMail("MatLABreferenced",1);
      else
         com_addref($this->MLab);
      $Nums = array();
      $Goals = array();
      if (isset($Y["IDs"]))
         {
          $Val = array();
          foreach ($Y["IDs"] as $Val1)
            $Val = array_merge($Val,$Val1);
          $Val = array_unique($Val);
          foreach ($Val as $ID)
            {
             if (isset($Nums[$ID]))
                $Nums[$ID] = 1;
             else
                $Nums[$ID]++;
             $Goals[$ID] .= ($Nums[$ID]>1 ? ";" : "").$this->Out;
            }
          foreach ($Goals as $ID => $Val)
            {
             if ($Nums[$ID]>1) $Val = "mean(".$Val.")";
             PutMail("Goal_".$ID,$Val);
            }
         }
      if ($this->Init!="")
         PutMail("Initialization",$this->Init);
      break;
    case stDone:
      if (($Time = GetNextMail("TIME"))!="")
         echo "Elapsed time = ",time()-$Time," sec.\n";
      $this->Selected = 0;
      for ($i=1; $i<$powY; $i++)
        if ($Y["R2Norm"][$i]<$Y["R2Norm"][$this->Selected])
           $this->Selected = $i;
      $Expression = $Y["Function"][$this->Selected];
      $Substs = array(".*" => "*", "./" => "/", ".^" => "^");
      foreach ($Substs as $What => $Subst)
        $Expression = str_replace($What,$Subst,$Expression);
      echo GetAns(com_invoke($this->MLab,"Execute","simplify(sym('$Expression'))"))."\n";
      com_release($this->MLab);
      $this->MLab = null;
      break;
  }
?>