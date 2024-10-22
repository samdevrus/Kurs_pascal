unit db;
interface
uses crt,gui;
const
   Nmax=82;
   bdfilename='slovar.db';
type

   REC=record
      name:string[15];
      cat:string[50];
      description,synonyms:string;
      abc_id,id:longint;
   end;
   recar=array[0..Nmax] of rec;
var
   f:file of rec;
   d:recar;
   ml:byte;

procedure open;
function load(start_id:word;byabc:boolean):word;
procedure echo_db;
function manage_list(max,id:byte):byte;
function write_list(max:byte):byte;
procedure sortbyabc;
implementation

{Очищает запись}
procedure empt_rec(var e:rec);
begin
   e.name:='';
   e.description:='';
   e.synonyms:='';
end;

procedure delete_record(real_id:word);
var
   rec_n:rec;
begin
   seek(f,app.fsize-1);
   read(f,rec_n);
   seek(f,app.fsize-1);
   truncate(f);
   reset(f);
   seek(f,real_id);
   write(f,rec_n);
   app.fsize:=app.fsize-1;
   reset(f);
end;

{Проверяет отсортирована ли БД по алфавиту}
function abc:boolean;
var
   tmp:rec;
   result:boolean;
begin
   seek(f,1);
   result:=false;
   while (not EoF(f)) or (result=true) do
   begin
      read(f,tmp);
      if tmp.abc_id=0 then result:=true;
   end;
   abc:=result;
end;

{Очищает резултаты сортировки по алфавиту}
procedure empt_sort;
var
   pos:longint;
   tmp:rec;
begin
   pos:=1;
   while pos<app.fsize do
   begin
      seek(f,pos);
      read(f,tmp);
      tmp.abc_id:=0;
      seek(f,pos);
      write(f,tmp);
      inc(pos);
   end;
   seek(f,1);
end;
{Очищает массив с записями}
procedure empt_ar(var e:recar);
var
   i:byte;
begin
   empt_rec(e[0]);
   for i:=1 to Nmax do e[i]:=e[0];
end;
{Загружает записи из файла в массив d}
function load(start_id:word;byabc:boolean):word;
var
   i:byte;
   tmp:rec;
begin
   seek(f,start_id);
   i:=0;
   empt_ar(d);
   if byabc then
   begin
      if abc=false then sortbyabc;
      while (i<=Nmax) and (i+start_id<app.fsize) do
      begin
        seek(f,1);
        repeat
           read(f,tmp);
        until tmp.abc_id=i+start_id;
        d[i]:=tmp;
        inc(i);
      end;
   end
   else while (not eof(f)) and (i<=Nmax) do
   begin
      read(f,d[i]);
      inc(i);
   end;
   load:=i-1;
end;

function WToStr(wrd:word):string;
var
  res:string;
  t:real;
begin
   res:='';
   repeat
   t:=wrd/10;
   res:=chr(round(frac(t)*10)+ord('0'));
   until t<1;
   WToSTR:=res;
end;

function out_rec(id:byte):byte;
var
   line:string;
   key:word;
   fin:boolean;
   function edit_rec:byte;
   var
      ke:word;
   begin
      fline('* F2 * Сохранить * Esc * Закончить редактирование * Del * Удалить запись');
      vcurs(true);
      repeat
         ke:=scankey;
         case ke of
            del: if win_ask('Удаление','Удалить запись') then delete_record(id+1);
         end;
      until ke=esc;
      fline(line);
   end;
begin
   line:='';
   if id>0 then line:='* '+chr(27)+'* Предыдущая запись ';
   if id<app.fsize-2 then line:=line+'* '+chr(26)+'* Следующая запись ';
   line:=line+'* ESC * К списку';
   if app.editor then line:=line+'* Enter * Редактировать';
   fline(line);
   TextColor(white);
   TextBackGround(1);
   window(2,3,79,23);
   clrscr;
   clrs(2,3,79,23);
   scrwrite('# записи :'+WtoSTR(id));
   writeln;
   scrwrite('Сокращение :'+d[id].name);
   writeln;
   scrwrite('Описание :'+d[id].description);
   writeln;
   scrwrite('Область применения :'+d[id].cat);
   writeln;
   scrwrite('Синонимы :'+d[id].synonyms);
   writeln;
   fin:=false;
   repeat
      key:=scankey;
      case key of
         left:if id>0 then
         begin
            out_rec:=id-1;
            fin:=true;
         end;
         right:if id<app.fsize-2 then
         begin
            out_rec:=id+1;
            fin:=true;
         end;
         enter:if app.editor then
         begin
            edit_rec;
            fin:=true;
            out_rec:=id;
         end;
         esc:
         begin
            fin:=true;
            out_rec:=id;
         end;
      end;
   until syskey(key) or fin;
   if syskey(key) then
   begin
      kr:=key;
      out_rec:=255;
   end;
end;



function write_list(max:byte):byte;
var
   j1,j2,xpos:byte;
   procedure writelist;
   var
      i:byte;
   begin
      clrscr;
      clrs(2,3,79,23);
      xpos:=1;
      GoToXY(xpos,1);
      for i:=0 to max do
      begin
         scrwrite(d[i].name);
         if wherey=21 then
         begin
            xpos:=xpos+15;
            GoToXY(xpos,1);
         end else GoToXY(xpos,wherey+1);
      end;
   end;
begin
   j2:=0;
   j1:=0;
   repeat
      if j2=j1 then j1:=255 else
      begin
         j2:=out_rec(j2);
         j1:=j2;
      end;
      if (j1=255) and (j2<>255) then
      begin
         writelist;
         j1:=manage_list(max,j2);
      end;
      if j1<>255 then j2:=out_rec(j1);
   until (j1=255) or (j2=255);
end;

function manage_list(max,id:byte):byte;
var
   xpos,ypos,i:byte;
   key:word;
   line:string;
begin
   line:='* Enter * Открыть запись * Tab * Меню *'+chr(27)+chr(24)+chr(26)+chr(25)+'* Перемещение *Alt+X * Выход';
   fline(line);
   window(2,3,79,23);
   if app.ppage then ypos:=2 else ypos:=1;
   xpos:=1+15*round(int( ( id+(ypos-1) )/21));
   ypos:=id-round(int( ( id+(ypos-1) )/21))*21+(ypos);
   GoToXY(xpos,ypos);
   refresh_text(7,1,d[id].name);
   i:=id;
   repeat
      key:=scankey;
      case key of
         up:
         begin
            if i>0 then
            begin
               GoToXY(xpos,wherey);
               refresh_text(1,white,d[i].name);
               if (wherey=1) and (xpos<>1) then
               begin
                  xpos:=xpos-15;
                  GoToXY(xpos,21)
               end else GoToXY(xpos,wherey-1);
               dec(i);
               refresh_text(7,1,d[i].name);
            end;
         end;
         down:
         begin
           if i<max then
            begin
               GoToXY(xpos,wherey);
               refresh_text(1,white,d[i].name);
               if wherey=21 then
               begin
                  xpos:=xpos+15;
                  GoToXY(xpos,1)
               end else GoToXY(xpos,wherey+1);
               inc(i);
               refresh_text(7,1,d[i].name);
            end;
         end;
         left:if xpos>1 then
         begin
            GoToXY(xpos,wherey);
            refresh_text(1,white,d[i].name);
            xpos:=xpos-15;
            GoToXY(xpos,wherey);
            i:=i-21;
            refresh_text(7,1,d[i].name);
         end;
         right:if ((xpos=1+(int(max/21)-1)*15) and
         (wherey<=(max-int(max/21)*21)+1)) or
                      (xpos<1+(int(max/21)-1)*15) then
                      begin
                         GoToXY(xpos,wherey);
                         refresh_text(1,white,d[i].name);
                         xpos:=xpos+15;
                         GoToXY(xpos,wherey);
                         i:=i+21;
                         refresh_text(7,1,d[i].name);
                      end;
          enter:;
      end;
   until (syskey(key)) or (key=enter);
   if syskey(key) then
   begin
      kr:=key;
      i:=255;
   end;
   manage_list:=i;
end;

{Выводит список записей}
{procedure out_list;
var
   i,xpos:byte;
   k,st_id:word;
   nextpage,readnext:boolean;
   procedure manage_list(const max,bg1,bg2,tc1,tc2:byte);
   var
      id:byte;
      r:rec;
      lisq:boolean;
      oo:word;
      {Вывод одной записи
      function out_one:word;
      var
         kc,k1:word;
         pos:byte;
         f_line:string;
         quit,quit1:boolean;
      begin
           textbackGround(bg1);
           TextColor(tc1);
           if id>0 then f_line:='*'+chr(26)+'* Предыдущая запись ';
           if ((id<max) and (nextpage=false)) or (id<max-1)
              then f_line:='*'+chr(27)+'* Следующая запись ';
           f_line:='* ESC * К списку';
           if app.editor then f_line:='* Enter * Редактировать';
           fline(f_line);
           window(2,3,79,23);
           clrscr;
           clrs(2,3,79,23);
           scrwrite('Сокращение :'+d[id].name);
           writeln;
           scrwrite('Описание :'+d[id].description);
           writeln;
           scrwrite('Область применения :'+d[id].cat);
           writeln;
           scrwrite('Синонимы :'+d[id].synonyms);
           writeln;
           quit:=false;
           repeat
                 kc:=scankey;
                 if syskey(kc) then
                 begin
                    skey:=true;
                    quit:=true;
                    kr:=kc;
                 end;
                 case kc of
                    enter:if app.editor then
                    begin
                       vcurs(true);
                       GoToXY(1,5);
                       delline;
                       delline;
                       fline('* F2 * Сохранить * Esc * Отмена редактирования ');
                       pos:=1;
                       GoToXY(13+length(d[id].name),pos);
                       {Переход к редактированию
                       repeat
                          k1:=scankey;
                          case k1 of
                             up:if pos>1 then
                             begin
                                dec(pos);
                                case pos of
                                   1:GoToXY(13+length(d[id].name),pos);
                                   2:GoToXY(11+length(d[id].description),pos);
                                   3:GoToXY(23+length(d[id].cat),pos);
                                   4:GoToXY(11+length(d[id].synonyms),pos);
                                end;
                             end;
                             down:if pos<4 then
                             begin
                                inc(pos);
                                case pos of
                                   1:GoToXY(13+length(d[id].name),pos);
                                   2:GoToXY(11+length(d[id].description),pos);
                                   3:GoToXY(23+length(d[id].cat),pos);
                                   4:GoToXY(11+length(d[id].synonyms),pos);
                                end;
                             end;
                             esc:quit1:=true;
                             f2:quit1:=true;
                             backspace:
                             begin
                                case pos of
                                   1:if wherex>13 then
                                   begin
                                      d[id].name[0]:=chr(ord(d[id].name[0])-1);
                                      GoToXY(wherex-1,pos);
                                      scrwrite(' ');
                                      GoToXY(wherex-1,pos);
                                   end;
                                   2:if wherex>11 then
                                   begin
                                      d[id].description[0]:=chr(ord(d[id].description[0])-1);
                                      GoToXY(wherex-1,pos);
                                      scrwrite(' ');
                                      GoToXY(wherex-1,pos);
                                   end;
                                   3:if wherex>21 then
                                   begin
                                      d[id].cat[0]:=chr(ord(d[id].cat[0])-1);
                                      GoToXY(wherex-1,pos);
                                      scrwrite(' ');
                                      GoToXY(wherex-1,pos);
                                   end;
                                   4:if wherex>11 then
                                   begin
                                      d[id].synonyms[0]:=chr(ord(d[id].synonyms[0])-1);
                                      GoToXY(wherex-1,pos);
                                      scrwrite(' ');
                                      GoToXY(wherex-1,pos);
                                   end;
                                end;
                             end;
                             48..255:
                             begin
                                case pos of
                                   1:d[id].name:=d[id].name+chr(k1);
                                   2:d[id].description:=d[id].description+chr(k1);
                                   3:d[id].cat:=d[id].cat+chr(k1);
                                   4:d[id].synonyms:=d[id].synonyms+chr(k1);
                                end;
                             scrwrite(chr(k1));
                          end;
                        end;
                       until quit1;
                       {Редактирование завершено
                    end;
                    left:if id>0 then quit:=true;
                    right:if ((id<max) and (nextpage=false)) or (id<max-1)
                             then quit:=true;
                    esc:quit:=true;
                 end;
           until quit;
           out_one:=kc;
      end;
   begin
        skey:=false;
        TextColor(tc2);
        TextBackGround(bg2);
        id:=0;
        k:=0;
        oo:=0;
        xpos:=1;
        GoToXY(xpos,id+1);
        scrwrite(D[id].name);
        lisq:=false;
        repeat
              if k=0 then k:=scankey;
              if syskey(k) then
              begin
                 skey:=true;
                 kr:=k;
              end;
              case k of
                   left:
                   begin
                      if (id=max) and (nextpage) then
                      begin
                         GoToXY(xpos,wherey);
                         TextColor(tc1);
                         TextBackGround(bg1);
                         scrwrite('Следующая стр.');
                         xpos:=xpos-15;
                         GoToXY(xpos,wherey);
                         id:=id-h;
                         TextColor(tc2);
                         TextBackGround(bg2);
                         scrwrite(d[id].name);
                      end else
                      if xpos>1 then
                      begin
                         GoToXY(xpos,wherey);
                         TextColor(tc1);
                         TextBackGround(bg1);
                         scrwrite(d[id].name);
                         xpos:=xpos-15;
                         GoToXY(xpos,wherey);
                         id:=id-h;
                         TextColor(tc2);
                         TextBackGround(bg2);
                         scrwrite(d[id].name);
                      end;
                      k:=0;
                   end;
                   right:
                   begin
                      if (id=max-h) and (nextpage) then
                      begin
                         GoToXY(xpos,wherey);
                         TextColor(tc1);
                         TextBackGround(bg1);
                         scrwrite(d[id].name);
                         xpos:=xpos+15;
                         GoToXY(xpos,wherey);
                         id:=id+h;
                         TextColor(tc2);
                         TextBackGround(bg2);
                         scrwrite('Следующая стр.');
                      end else
                      if ((xpos=1+(int(max/h)-1)*15) and
                      (wherey<=(max-int(max/h)*h)+1)) or
                      (xpos<1+(int(max/h)-1)*15) then
                      begin
                         GoToXY(xpos,wherey);
                         TextColor(tc1);
                         TextBackGround(bg1);
                         scrwrite(d[id].name);
                         xpos:=xpos+15;
                         GoToXY(xpos,wherey);
                         id:=id+h;
                         TextColor(tc2);
                         TextBackGround(bg2);
                         scrwrite(d[id].name);
                      end;
                      k:=0;
                   end;
                   down:{Dow
                   begin
                        if (id=max-1) and (nextpage) then
                        begin
                           GoToXY(xpos,wherey);
                           TextColor(tc1);
                           TextBackGround(bg1);
                           scrwrite(d[id].name);
                           if wherey=h then
                           begin
                              xpos:=xpos+15;
                              GoToXY(xpos,1)
                           end else GoToXY(xpos,wherey+1);
                           inc(id);
                           TextColor(tc2);
                           TextBackGround(bg2);
                           scrwrite('Следующая стр.');
                        end else
                        if id<max  then
                        begin
                           GoToXY(xpos,wherey);
                           TextColor(tc1);
                           TextBackGround(bg1);
                           scrwrite(d[id].name);
                           if wherey=h then
                           begin
                              xpos:=xpos+15;
                              GoToXY(xpos,1)
                           end else GoToXY(xpos,wherey+1);
                           inc(id);
                           TextColor(tc2);
                           TextBackGround(bg2);
                           scrwrite(d[id].name);
                        end;
                        k:=0;
                   end;
                   up:{Up
                   begin
                      if (id=max) and (nextpage) then
                      begin
                         GoToXY(xpos,wherey);
                         TextColor(tc1);
                         TextBackGround(bg1);
                         scrwrite('Следующая стр.');
                         if wherey=1 then
                         begin
                              xpos:=xpos-15;
                              GoToXY(xpos,h)
                         end else GoToXY(xpos,wherey-1);
                         dec(id);
                         TextColor(tc2);
                         TextBackGround(bg2);
                         scrwrite(d[id].name);
                      end else
                      if id>0 then
                      begin
                         GoToXY(xpos,wherey);
                         TextColor(tc1);
                         TextBackGround(bg1);
                         scrwrite(d[id].name);
                         if wherey=1 then
                         begin
                              xpos:=xpos-15;
                              GoToXY(xpos,h)
                         end else GoToXY(xpos,wherey-1);
                         dec(id);
                         TextColor(tc2);
                         TextBackGround(bg2);
                         scrwrite(d[id].name);
                      end;
                      k:=0;
                   end;
                   enter:{Enter
                   begin
                      if (id=max) and (nextpage) then
                      begin
                         lisq:=true;
                         nextpage:=false;
                         readnext:=true;
                         inc(st_id);
                      end else
                      begin
                         oo:=out_one;
                         case oo of
                            left:begin dec(id); k:=enter;  end;
                            right:begin inc(id); k:=enter; end;
                            esc:lisq:=true;
                            tab:skey:=true;
                         else k:=0;
                      end;
                      end;
                   end
                   else k:=0;
              end;
     until (skey) or (lisq);
   end;
begin
   st_id:=1;
   readnext:=false;
   Nextpage:=false;
   if readfromfile then ml:=load(st_id,true);
   repeat
   if readnext then ml:=load(st_id,true);
   xpos:=1;
   TextBackGround(1);
   TextColor(white);
   clrscr;
   clrs(2,3,79,23);
   for i:=0 to ml do
   begin
      scrwrite(d[i].name);
      if (wherey=h) then
      begin
         xpos:=xpos+15;
         GoToXY(xpos,1);
      end else GoToXY(xpos,wherey+1);
   end;
   if app.fsize>ml+2+(st_id-1)*(Nmax+1) then
   begin
      scrwrite('Следующая стр.');
      nextpage:=true;
      inc(ml);
   end;
   manage_list(ml,1,7,white,black);
   if nextpage then dec(ml);
   until skey;
end;
{Поднимает все буквы}
function up(s:string):string;
var
   b:byte;
   res:string;
begin
   res:='';
   for b:=1 to length(s) do
      if s[b] in ['а'..'п'] then
         res:=res+chr(ord('А')+(ord(s[b])-ord('а')))
      else if s[b] in ['р'..'я'] then
               res:=res+chr(ord('Р')+(ord(s[b])-ord('р')))
           else res:=res+UpCase(s[b]);
   up:=res;
end;
{Создание новой БД}
procedure create;
var
   i:integer;
   j:byte;
   rec_i:rec;
begin
   clrscr;
   scrwrite('Создание новой базы данных.');
   rewrite(f);
   scrwrite('Введите пароль редактора:');
   read(rec_i.name);
   write(f,rec_i);
   delline;
   i:=1;
   repeat
      empt_rec(rec_i);
      writeln('Ввод записи №',i);
      write('Сокращение:');
      repeat
         readln(rec_i.name);
      until rec_i.name<>'';
      rec_i.name:=Up(rec_i.name);
      write('Описание:');
      repeat
         readln(rec_i.description);
      until rec_i.description<>'';
      write('Область применения:');
      repeat
         readln(rec_i.cat);
      until rec_i.cat<>'';
      write('Синонимы:');
      readln(rec_i.synonyms);
      rec_i.id:=i;
      inc(i);
      write(f,rec_i);
      writeln('Нажмите любую клавишу для ввода записи №',i);
      scrwrite('Нажмите [Esc] для сохранения файла');
      writeln;
   until readkey=chr(esc);
   close(f);
end;
{Открытие БД}
procedure open;
var
   rec_1:rec;
begin
   if app.fileopened=false then
   begin
      assign(f,bdfilename);
      {$I-}
      reset(f);
      if IOResult<>0 then
      begin
         scrwrite('База данных не найдена');
         writeln;
         {Создание и сохранение новой БД}
         create;
         {Открытие БД}
         open;
      end else
      begin
         app.fsize:=filesize(f);
         app.fileopened:=true;
         seek(f,0);
         read(f,rec_1);
         app.password:=rec_1.name;
      end;
   end;
   {$I+}
   seek(f,1);
end;
{Сортировка по алфавиту}
procedure sortbyabc;
var
   i,j,id:word;
   t1,t2:rec;
begin
   empt_sort;
   id:=1;
   repeat
      i:=1;
      repeat
         seek(f,i);
         read(f,t1);
         inc(i);
      until (t1.abc_id=0) or (i=app.fsize);
      dec(i);
      for j:=1 to app.fsize-1 do
      begin
         seek(f,j);
         read(f,t2);
         if (t1.name>t2.name) and (t2.abc_id=0) then t1:=t2;
      end;
      t1.abc_id:=id;
      seek(f,t1.id);
      write(f,t1);
      inc(id);
   until id=app.fsize;
end;

procedure echo_db;
var
   tmp:rec;
begin
   seek(f,1);
   writeln('fsize=',app.fsize);
   while not EoF(f) do
   begin
      read(f,tmp);
      writeln(tmp.name);
      writeln('id=',tmp.id,' abc_id=',tmp.abc_id);
   end;
   readln;
end;

begin
   app.fsize:=0;
   app.fileopened:=false;
   app.editor:=false;
   app.alphabet:=false;
   app.npage:=false;
   app.ppage:=false;
end.
