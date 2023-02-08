<?php
  if ($Stage!=stResource)
     AnalyzeInput($powX,$X);
  foreach ($X as $K => $V)
    if ($K != "_ID" && $K != "_ClassID" && $K != "_LinkID")
       $Val[$K] = $V;
?>