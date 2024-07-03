<?php
  $Code = '<Input Type="button" Name="'.$this->ID.'" Value="'.$this->Text.'"/>';
  cortege_push($Form["HTML"],$Code);
  cortege_push($Form["Items"],array($this->ID,$Code));
?>