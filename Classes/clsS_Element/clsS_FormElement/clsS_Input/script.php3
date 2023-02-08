<?php
  $Code = '<Input Type="'.
          ($this->Type=="Обычный" ? "text" : "password").
          '" Name="'.$this->ID.'" Value="'.$this->Type.'"/>';
  cortege_push($Form["HTML"],$Code);
  cortege_push($Form["Items"],array($this->ID,$Code));
?>