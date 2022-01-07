%TestID=Test2auto
%Тест на способность к концентрации внимания

Text(Prompt)
     При  ответе  на  каждый  вопрос Вам предлагается несколько вариантов ответа.
Выберите один  из  вариантов  и нажмите соответствующую кнопку.  Всего  Вы должны
ответить на 10 вопросов.
EndT

Answer(A1,1)
  &EqualButtons
  @Почти всегда
  @В большинстве случаев
  @Иногда
  @Редко
  @Почти никогда
EndA

Question(Q1):A1
   Вопрос 1
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Стараетесь ли Вы "свернуть" беседу в  тех  случаях,  когда  тема  (или
собеседник) неинтересны Вам?
EndQ

Question(Q2):A1
   Вопрос 2
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Раздражают ли Вас манеры Вашего партнера по общению?
EndQ

Question(Q3):A1
   Вопрос 3
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Может ли  неудачное  выражение  другого человека спровоцировать Вас на
резкость или грубость?
EndQ

Question(Q4):A1
   Вопрос 4
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Избегаете ли Вы вступать в разговор с неизвестным или малознакомым Вам
человеком?
EndQ

Question(Q5):A1
   Вопрос 5
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Имеете ли Вы привычку перебивать говорящего?
EndQ

Question(Q6):A1
   Вопрос 6
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Делаете ли Вы вид,  что внимательно слушаете,  а сами думаете совсем о
другом?
EndQ

Question(Q7):A1
   Вопрос 7
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Меняете ли Вы тон,  голос,  выражение лица в зависимости от того,  кто
Ваш собеседник?
EndQ

Question(Q8):A1
   Вопрос 8
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Меняете ли  Вы  тему  разговора,  если  он коснулся неприятной для Вас
темы?
EndQ

Question(Q9):A1
   Вопрос 9
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Поправляете ли Вы человека,  если в его речи  встречаются  неправильно
произнесенные слова, название, вульгаризмы?
EndQ

Question(Q10):A1
   Вопрос 10
   &Empty
   &Font('Courier New Cyr',11,clBlack,0,0,0)
Бывает ли у Вас снисходительно-менторский тон с оттенком пренебрежения
и иронии по отношению к тому, с кем вы говорите?
EndQ

Answer(A2,1)
  @ Закончить тестирование
EndA

Question(Q11):A2
   &Font('Courier New Cyr',11,clBlack,1,0,0)
   Вы  ответили  на  все  предложенные  Вам  вопросы. Если вы
   желаете  откорректировать свои ответы,  то выберите нужный
   вопрос (вопросы)  с  помощью кнопок "Вперед" и "Назад". По
   окончании  исправлений  вернитесь в  конец теста и нажмите
   кнопку "Закончить тестирование"
EndQ

Text(T1)
Умение слушать недостаточно развито
EndT

Main
  Size(obWindow,800,600)
  Title('Тест на способность к концентрации внимания')
  ShowPrompt(Prompt)
  Size(obQuestionPanel,2,75,650,235)
  Font(obQuestionPanel,'Times New Roman Cyr',14,clNavy,1,1,1)
  Color(obQuestionPanel,RGB(176,208,176))
  Size(obAnswerPanel,2,315,650,255)
  Font(obAnswerPanel,'Arial Cyr',10,clNavy,0,0,0)
  Color(obAnswerPanel,RGB(208,208,160))
  Size(obHandlePanel,655,75,141,495)
  Font(obHandlePanel,'Times New Roman Cyr',14,clBlack,0,0,0)
  Color(obHandlePanel,clBtnFace)
  HandlePanel(hbBack,hbForward)
  Open
  Ask(Q1,Q2,Q3,Q4,Q5,Q6,Q7,Q8,Q9,Q10,Q11)
  SaveResults
  Define qC:Array[1:10] = {&Q1,&Q2,&Q3,&Q4,&Q5,&Q6,&Q7,&Q8,&Q9,&Q10}
  Define aC:Array[1:5] = {1,2,3,4,5}
  Define sC:Array[1:5] = {2,4,6,8,10}
  Define C:Number = 0
  Define cC1:Number
  Define cC:Number = 1
  While (cC<=10)
    cC1:=1
    While (cC1<=5)
      If qC[cC]=aC[cC1]
         C := C+sC[cC1]
      EndIf
      cC1:=cC1+1
    EndW
    cC:=cC+1
  EndW

  Define nfS:Number = 1
  Define normS:Array[2:3] = {50,60}
  Define S:Number = 3
  While (S>1 And nfS)
    If (C>=normS[S])
       nfS:=0
    Else
       S:=S-1
    EndIf
  EndW

  Define Texts1:String = 'Умение слушать находится в пределах нормы'
  Define Texts2:String = 'Умение слушать развито в высокой степени'
  Define Texts:Array[1:3] = {#T1,#Texts1,#Texts2}
  Define textTexts:Array[1:3] = {1,0,0}
  ClearPut
  PutTitle('Результаты')
  PutLine('Количество баллов = ',C)
  If textTexts[S]
     PutText(GetTextByPtr(Texts[S]))
  Else
     PutLine(?Texts[S])
  EndIf

  ShowPut
  Exit
EndM
