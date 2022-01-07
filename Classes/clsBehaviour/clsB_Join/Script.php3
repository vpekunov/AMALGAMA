<?
  if ($Stage==stDone)
     {
      $Report = array();
      $PlBase = array();
      $TaskFName = "_".$this->Session.".session";
      $Task = file($TaskFName);
      unlink($TaskFName);
      $NumTasks = floor($Task[0]);
      $WaitSet = range(0,$NumTasks-1);
      while (!empty($WaitSet))
        {
         foreach ($WaitSet as $ID=>$Val)
           {
            $Base = "_".$this->Session.".".$ID;
            if (file_exists($Base.".ok"))
               {
                unlink($Base.".ok");
                $Report[$ID] = implode("",file($Base.".out"));
                if (file_exists($Base."._out.pl"))
                   {
                    $Info = file($Base."._out.pl");
                    if (count($Info)>0)
                       unset($Info[count($Info)-1]);
                    if (isset($Info[0]))
                       unset($Info[0]);
                    $PlBase[$ID] = implode("",$Info);
                    unlink($Base."._out.pl");
                   }
                unlink($Base.".out");
                unset($WaitSet[$ID]);
               }
           } 
         sleep(1);
        }
      if (!empty($PlBase))
         {
          $Pl = fopen("_out.pl","wb");
          fwrite($Pl,"use_outs:-\n");
          fwrite($Pl,implode("\n",$PlBase));
          fclose($Pl);
         }
      echo implode("\n",$Report)."\n";
     }
?>