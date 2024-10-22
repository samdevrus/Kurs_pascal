unit gui;
interface
uses crt,dos;
type
   inf=record
      fsize:longint;
      password:string[15];
      cur_line:string;
      fileopened,editor,alphabet,npage,ppage:boolean;
   end;
const
   {keys}
   alt_x=1045;
   backspace=8;
   tab=9;
   enter=13;
   esc=27;
   f1=1059;
   f2=1060;
   up=1072;
   down=1080;
   left=1075;
   right=1077;
   {xxx}
   menu_0:array[0..4] of string=('Главное меню','Словарь','Поиск',
                      'Сортировка','База данных');
   menu_1:array[0..3] of string=('С','Отобразить все','Настройки','Выход');
   menu_2:array[0..3] of string=('П','Ввести сокращение',
                      'Ввести синоним','Поиск по пояснению');
   menu_3:array[0..2] of string=('С','По алфавиту',
                      'По дате добавления');
   menu_4:array[0..4] of string=('Б','Режим редактора','Режим пользователя',
                      'Создать\Сменить БД','Удалить');
var
   screen:array[0..79,0..24] of char;
   kr:word;
   skey:boolean;
   app:inf;

procedure win(x1,y1,x2,y2,tc,bgc:byte;header:string;save:boolean);
procedure scrfill(x1,y1,x2,y2,tc,bgc:byte);
procedure scrwrite(const s:string);
function syskey(kl:word):boolean;
procedure clrs(x1,y1,x2,y2:byte);
function win_input(x1,y1,x2,y2,tc,bgc:byte;header,caption:string):string;
function scankey:word;
procedure fline(line:string);
procedure vcurs(flag:boolean);
procedure refresh_text(const tc,bgc:byte;st:string);
function hmenu(menu_i:array of string;bg1,bg2,tc1,tc2:byte):byte;
procedure showmessage(x1,y1,x2,y2,tc,bgc:byte;header,message:string);
function win_ask(header,question:string):boolean;

implementation

{Считывает код нажатой клавиши}
function scankey:word;
var
   ch:char;
   res:word;
begin
   ch:=readkey;
   res:=ord(ch);
   if res=0 then res:=1000+ord(readkey);
   scankey:=res;
end;

{Выводит окно с вопросом}
function win_ask(header,question:string):boolean;
var
   k:word;
begin
   fline('* Enter * Выбрать *'+chr(27)+chr(26)+'* Перемещение');
   win(20,10,52,14,Black,white,header,false);
   writeln(question);
   write('          ');
   textcolor(white);
   textBackGround(blue);
   write(' Да ');
   textcolor(black);
   textBackGround(white);
   write(' Нет ');
   GoToXY(20,2);
   repeat
      k:=scankey;
      case k of
         left:
         begin
            if wherex=15 then
            begin
               GoToXY(15,2);
               textcolor(black);
               textBackGround(white);
               write(' Нет ');
               GoToXY(11,2);
               textcolor(white);
               textBackGround(blue);
               write(' Да ');
               GoToXY(20,2);
            end;
         end;
         right:
         begin
            if wherex=20 then
            begin
               GoToXY(11,2);
               textcolor(black);
               textBackGround(white);
               write(' Да ');
               GoToXY(15,2);
               textcolor(white);
               textBackGround(blue);
               write(' Нет ');
               GoToXY(15,2);
            end;
         end;
      end;
   until k=enter;
   case wherex of
      20:win_ask:=true;
      15:win_ask:=false;
   end;
   scrfill(20,10,55,14,7,1);
   fline(app.cur_line);
end;

{Вывод окно с сообщением}
procedure showmessage(x1,y1,x2,y2,tc,bgc:byte;header,message:string);
var
   k:word;
begin
   win(x1,y1,x2,y2,tc,bgc,header,false);
   writeln(message);
   GoToXY(round((x2-x1)/2)-2,wherey);
   TextColor(bgc);
   TextBackGround(tc);
   write(' OK ');
   fline('* Enter/Esc * Закрыть сообщение');
   repeat
      k:=scankey;
   until k in [13,27];
   scrfill(x1,y1,x2,y2,white,1);
   fline(app.cur_line);
   kr:=0;
end;

{Выводит нижнюю строку}
procedure fline(line:string);
var
   i:byte;
   red_color:boolean;
begin
   window(1,1,80,25);
   GoToXY(1,25);
   TextBackGround(7);
   clreol;
   GoToXY(1,25);
   red_color:=false;
   textColor(black);
   for i:=1 to length(line) do
   begin
      case line[i] of
         '*':
         begin
            red_color:=not(red_color);
            if red_color=false then textColor(black) else
            textColor(red);
         end;
         else scrwrite(line[i]);
      end;
   end;
end;

{Проверяет на нажатие системной клавиши}
function syskey(kl:word):boolean;
begin
   case kl of
      f1:syskey:=true;
      alt_x:syskey:=true;
      tab:syskey:=true;
   else syskey:=false;
   end;
end;

{Выводит текст и сохраняет его в массив}
procedure scrwrite;
var
   k,wxs,wys:byte;
begin
   k:=1;
   wxs:=Lo(WindMin);
   wys:=Hi(windMin);
   while k<=length(s) do
   begin
      screen[wherex-1+wxs,wherey-1+wys]:=s[k];
      write(s[k]);
      inc(k);
   end;
end;

{Восстанавливает участок экрана по массиву scr}
procedure scrfill(x1,y1,x2,y2,tc,bgc:byte);
var
   x,y:byte;
begin
   window(1,1,80,25);
   TextColor(tc);
   TextBackGround(bgc);
   for y:=y1 to y2 do
      for x:=x1 to x2 do
      begin
         GoToXY(x,y);
         write(screen[x-1,y-1]);
      end;
end;

{Очищает часть массива scr}
procedure clrs(x1,y1,x2,y2:byte);
var
   i,j:byte;
begin
   for i:=y1-1 to y2-1 do
      for j:=x1-1 to x2-1 do
         screen[j,i]:=' ';
end;
{Maxl определяет максимальную длинну строки в массиве}
function maxl(am:array of string):byte;
var
   k,m:byte;
begin
   m:=0;
   for k:=0 to high(am) do
      if m<length(am[k]) then m:=length(am[k]);
   maxl:=m;
end;
{Max определяет максимальное из двух чисел}
function max(i,j:integer):integer;
begin
   if i>j then max:=i else max:=j;
end;
{winr выводит окно с рамкой и заголовком}
procedure win;
var
   i:byte;
begin
   TextColor(tc);
   TextBackGround(bgc);
   window(x1,y1,x2,y2);
   if save=false then write(chr(201)) else scrwrite(chr(201));
   for i:=2 to (x2-x1) do
   begin
      GoToXY(i,1);
      if save=false then write(chr(205)) else scrwrite(chr(205));
      GoToXY(i,(y2-y1));
      if save=false then write(chr(205)) else scrwrite(CHR(205));
   end;
   if save=false then write(chr(188)) else scrwrite(chr(188));
   GoToXY((x2-x1+1),1);
   if save=false then write(chr(187)) else scrwrite(chr(187));
   for i:=2 to (y2-y1-1) do
   begin
      GoToXY(1,i);
      if save=false then write(chr(186)) else scrwrite(chr(186));
      GoToXY((x2-x1+1),i);
      if save=false then write(chr(186)) else scrwrite(chr(186));
   end;
   if save=false then write(chr(200)) else scrwrite(chr(200));

   if header<>'' then
   begin
      GoToXY(round((x2-x1)/2)-round(length(header)/2),1);
      if save=false then write(header) else scrwrite(header);
   end;
   window(x1+1,y1+1,x2-1,y2-2);
   clrscr;
end;

{Прячет курсор}
procedure vcurs(flag:boolean);
const
   sizeCursor:word=50;
var
   Reg:Registers;
begin
   with Reg do
   begin
      if flag then Cx:=SizeCursor else
      begin
         BH:=0;
         AH:=03;
         Intr($10,reg);
         SizeCursor:=CX;
         CH:=$20;
      end;
      AH:=01;
      Intr($10,Reg);
   end;
end;

{Выводит окно для ввода строки}
function win_input(x1,y1,x2,y2,tc,bgc:byte;header,caption:string):string;
var
   k:word;
   inp:string;
   quit:boolean;
begin
   fline('* Enter/Esc * Завершить ввод * Backspace * Удалить');
   win(x1,y1,x2,y2,tc,bgc,header,false);
   write(caption);
   TextBackGround(tc);
   TextColor(bgc);
   clreol;
   quit:=false;
   inp:='';
   GoToXY(length(caption)+1,1);
   repeat
      k:=scankey;
      case k of
         enter:quit:=true;
         esc:quit:=true;
         backspace:
         if wherex>length(caption)+1 then
         begin
            inp[0]:=chr(ord(inp[0])-1);
            GoToXY(wherex-1,wherey);
            write(' ');
            GoToXY(wherex-1,wherey);
         end;
         else if (k>49) and (k<255) and (wherex<x2-x1-1) then
         begin
            write(chr(k));
            inp:=inp+chr(k);
         end;
      end;
   until quit;
   if k=esc then win_input:='' else win_input:=inp;
   scrfill(x1,y1,x2,y2,white,1);
   fline(app.cur_line);
end;

{Меняет фон и цвет текста пункта меню}
procedure refresh(n,c1,c2:byte;menu_i:array of string);
var
   i,p:byte; { p- позиция по оси X }
begin
   p:=1;
   TextBackGround(c1);
   TextColor(c2);
   for i:=1 to n-1 do
      p:=p+length(menu_i[i])+2;
   gotoxy(p,wherey);
   write(' '+menu_i[n]+' ');
end;

procedure refresh_text(const tc,bgc:byte;st:string);
begin
   TextBackGround(tc);
   TextColor(bgc);
   scrwrite(st);
end;

{Функция обрабатывает нажатие клавиш при управлении горизон. меню}
function hmenu(menu_i:array of string;bg1,bg2,tc1,tc2:byte):byte;
var
   c:integer;
   wm,nm,lstr,yy,p,i,x1,x2,y1,y2:byte;
   {Управление выпадающим меню}
   function podmenu(menu_j:array of string):byte;
   var
      ct:word;
      quit:boolean;
      ni,q,pos:byte;
   begin
      {Определение позиции}
      pos:=1;
      for q:=1 to nm-1 do
         pos:=pos+length(menu_i[q])+2;
      x2:=pos+maxl(menu_j)+2;
      y2:=wherey+3+high(menu_j);
      y1:=wherey+1;
      x1:=pos;
      win(pos,y1,x2,y2,tc1,bg1,'',false);
      ni:=1; {nm - индекс массива главного меню}
      {Вывод меню}
      TextBackGround(bg2);
      TextColor(tc2);
      write(menu_j[ni]);
      TextBackGround(bg1);
      TextColor(tc1);
      for q:=2 to high(menu_j) do
      begin
         GoToXY(1,q);
         write(menu_j[q]);
      end;
      clreol;
      quit:=false;
      repeat
         ct:=scankey;
         case ct of
         up:{Вверх}
         begin
            GoToXY(1,ni);
            textcolor(tc1);
            textbackground(bg1);
            clreol;
            write(menu_j[ni]);
            dec(ni);
            if ni<1 then ni:=high(menu_j);
            GoToXY(1,ni);
            textcolor(tc2);
            textbackground(bg2);
            clreol;
            write(menu_j[ni]);
         end;
         down:{Вниз}
         begin
            GoToXY(1,ni);
            textcolor(tc1);
            textbackground(bg1);
            clreol;
            write(menu_j[ni]);
            inc(ni);
            if ni>high(menu_j) then ni:=1;
            GoToXY(1,ni);
            textcolor(tc2);
            textbackground(bg2);
            clreol;
            write(menu_j[ni]);
         end;
         left:
         begin
            podmenu:=254;
            quit:=true;
         end;
         right:
         begin
            podmenu:=255;
            quit:=true;
         end;
         esc:
         begin
            podmenu:=0;
            quit:=true;
         end;
         enter:
         begin
            podmenu:=ni+5*(nm-1);
            quit:=true;
         end;
         end;
      until syskey(ct) or quit;
      if syskey(ct) then
      begin
         podmenu:=0;
         kr:=ct;
         hmenu:=0;
      end;
      GoToXY(1,1);
   end;
begin
   p:=0;
   nm:=1; {nm - индекс массива меню}
   {Вывод меню}
   TextBackGround(bg2);
   TextColor(tc2);
   scrwrite(' '+menu_i[1]+' ');
   TextBackGround(bg1);
   TextColor(tc1);
   for i:=2 to high(menu_i) do scrwrite(' '+menu_i[i]+' ');
   clreol;
   repeat
      c:=scankey;
      case c of
         left:{Стрелка влево}
         begin
            refresh(nm,bg1,tc1,menu_i);
            if nm>1 then
            begin
               dec(nm);
            end else
            begin
               nm:=high(menu_i);
            end;
            refresh(nm,bg2,tc2,menu_i);
         end;
         right:{Стрелка вправо}
         begin
            refresh(nm,bg1,tc1,menu_i);
            if nm<high(menu_i) then
            begin
               inc(nm);
            end else nm:=1;
            refresh(nm,bg2,tc2,menu_i);
         end;
         up:{Стрелка вверх}
         begin
         end;
         down,enter:{Стрелка вниз}
         begin
            repeat
               case nm of
                  1:p:=podmenu(menu_1);
                  2:p:=podmenu(menu_2);
                  3:p:=podmenu(menu_3);
                  4:p:=podmenu(menu_4);
               end;
               scrfill(x1,y1,x2,y2,white,1);
               window(1,1,80,25);
               if p=254 then
               begin
                  refresh(nm,bg1,tc1,menu_i);
                  dec(nm);
                  if nm=0 then nm:=high(menu_i);
                  refresh(nm,bg2,tc2,menu_i);
               end;
               if p=255 then
               begin
                  refresh(nm,bg1,tc1,menu_i);
                  inc(nm);
                  if nm=high(menu_i)+1 then nm:=1;
                  refresh(nm,bg2,tc2,menu_i);
               end;
            until (p in [254,255])=false;
            if p<>0 then
            begin
               hmenu:=p;
            end;
          end;
      end;
   until (p<>0) or ((kr<>9) or (syskey(c)));
   refresh(nm,bg1,tc1,menu_i);
   if syskey(c) then
   begin
      kr:=c;
      hmenu:=0;
   end;
end;
begin
   clrs(1,1,80,25);
end.

