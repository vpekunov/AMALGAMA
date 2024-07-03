<?php
switch ($Stage) {
  case stCall:
    echo "Links = ".$Eqtns["Variable"][0].";\n";
    echo "Mins = [".implode(";",$Eqtns["Mins"])."];\n";
    echo "Maxes = [".implode(";",$Eqtns["Maxes"])."];\n";
    echo "sVars = {".implode(";",$Eqtns["sVars"])."};\n";
?>
FuncsP = cell(3,1);
FuncsM = cell(3,1);
[Num One] = size(sVars);
for j = 1:3
  for i = 1:Num
    XX = ['X(' '0'+i +')'];
    Links(j) = sym(strrep(char(Links(j)),sVars{i},XX));
  end;
  Constr = sym('0');
  for i = 1:Num
    XX = ['X(' '0'+i +')'];
    if (~isinf(Mins(i)))
       Constr = sym([char(Constr) '+1000*(abs(' XX '-' num2str(Mins(i)) ')-(' XX '-' num2str(Mins(i)) '))']);
    end;
    if (~isinf(Maxes(i)))
       Constr = sym([char(Constr) '+1000*(abs(' XX '-' num2str(Maxes(i)) ')+(' XX '-' num2str(Maxes(i)) '))']);
    end;
  end;
  FuncsP{j} = inline(char(Links(j)+Constr),'X');
  FuncsM{j} = inline(char(1/(Links(j)+10)+Constr),'X');
end;

Area = zeros(3,2);
X0   = zeros(Num,1);
for j = 1:3
  Area(j,1) = FuncsP{j}(fminsearch(FuncsP{j},X0));
  Area(j,2) = FuncsP{j}(fminsearch(FuncsM{j},X0));
end;
<?php
    break;
}
cortege_push($Result["Variable"],"Area");
cortege_push($Result["Caption"],"Границы рабочей зоны");
?>
