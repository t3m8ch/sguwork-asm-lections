= Вложенные циклы

В матрице байтовых величин размером 4 на 5 нужно подсчитать количество
нулей в каждой строке, заменить нули константой `0FFh` и вывести количество
нулей на экран.

Оформляем при помощи двух последовательных процедур.

```
title prim.asm  ; определяет заголовок каждой страницы листинга
                ; может содержать до 60 символов
page , 132      ; определяет количство строк на странице листинга
                ; и символов в строке
                ; первый параметр -- количество строк (по-умолчанию 57)
                ; второй параметр -- количество символов в строке (по-умолчанию 80)
                ; page без параметров, если встретится в любом месте программы,
                ; осуществит переход на следующую страницу листинга

Sseg segment para stack 'stack'
  db 256 dup (?)
Sseg ends

Dseg segment para public 'data'   ; para - адрес сегмента должен быть кратен 16
  Dan db 0,  2,  5, 0,  91        ; адрес первого элемента массива
      db 4,  0,  0, 15, 47        ; имя - Dan
      db 24, 15, 0, 9,  55        ; адрес первого элемента массива -- Dan
      db 1,  7,  12,0,  4         ; Dan -- это символическое имя адреса на первый элемент
Dseg ends

Cseg segment para public 'code'
  Assume CS:Cseg, DS:Dseg, SS:Sseg

  start proc far
    push DS
    ; иногда пишут XOR AX, AX
    push AX
    mov BX, Dseg ; загружаем адрес сегмента данных
    mov DS, BX   ; мы не можем загружать напрямую в DS, поэтому сначала грузим в BX
    call main
    ret
  start endp

  main proc near
    mov BX, offset Dan           ; либо LEA BX, Dan
    mov CX, 4                    ; количетсво повторений внешнего цикла
    nz1: push CX
      mov DL, 0                  ; счётчик нулей в строке матрицы
      mov SI, 0
      mov CX, 5                  ; количество повторений внутреннего цикла
      nz2: push CX
        cmp byte ptr [BX+SI], 0
        jne mz
          mov byte ptr [BX+SI], 0FFh
          inc DL
        mz: inc SI
          pop CX
      kz2: loop nz2
        add DL, '0'              ; вывод на экран
        mov AH, 6                ; количество нулей
        int 21h
          add BX, 5              ; переход к следующей строке матрицы
          pop CX                 ; восстановили количество повторений внешнего цикла
      kz1: loop nz1
        ret
  main endp
Cseg ends

end start

; Можно не класть количество итераций ВНУТРЕННЕГО цикла в стек, тем самым упростив программу
```

= Массивы в Ассемблере

Массивы определяются директивами определения данных.

Например, одномерный массив слов размером из 30 элементов: `x DW 30 dup (?)`.
Выделили место и запомнили, где этот массив находится в переменной `x`.

Можно индексировать от 0 (тогда x = 0, 1, ..., 29). Можно от единицы, а можно
от любого другого произвоильного элемента, в зависимости от условия задачи. Но
если нет дополнительных требований, то удобно работать с массивом с индексацией
от нуля. Тогда адрес любого одномерного элемента можно вычислить по формуле:

```
адрес (x[i]) = x + (type x) * i
type x - размер элемента в памяти
```

Если нумерация произвольная, то формула такая:

```
адрес (x[i]) = x + (type x) * (i - k)
```

Для двумерного массива A[0..n-1, 0..m-1] адрес (i,j), то формула такая:

```
адрес (A[i,j]) = A + m * (type A) * i + (type A) * j
```

С учётом этих формул для записи адреса элемента массива можно использовать
можно использовать различные способы адресации.

```
x + 2*i = x + type(x) * i
где x - адрес начала массива (всегда остаётся постоянной)
i - переменная, которую мы можем хранить в одном из индексных регистров
```

Значит адресация прямая с индексированием.

Для двумерного массива (выделите место под двумерный массив двойных слов размерности N x N):

```
A DD n DUP (m Dup (?))
```

Адрес: `(A[i,j] = A + m*4*i + i + 4*j)`

Запишем количество строк матрицы X байтовых элементов, размерности 10 на 20, в которых
начальный элемент повторился хотя бы один раз:

```
-----/-----
mov AL, 0           ; количество искомых строк
mov CX, 10          ; количество повторений внешнего цикла
mov BX, 0           ; начала строки 20*i
m1:
  push CX
  mov AH, X[BX]     ; первый элемент строки в AH
  mov CX, 19        ; количество повторений внутреннего цикла
  mov DI, 0         ; номер элемента в строке (j)
m2:
  inc DI
  cmp AH, X[BX][DI] ; A[i, 0] = A[i, j]
  loopne m2         ; первый не повторился? Переход на m2
  jne L             ; не было в строке равных первому? Переход на L
  inc AL            ; первый повторился, увеличиваем счётчик строк
L:
  pop CX            ; восстанавливаем CX для внешнего цикла
  add BX, 20        ; в BX начало следующей строки
  loop m1
-----/-----
```

= Команды побитовой обработки данных

К ним относятся *логические команды*, *команды сдвига*, *установки*, *сброса*, *инверсии битов*.

+ *Логические команды* -- `and`, `or`, `xor`, `not`

  OF и CF = 0, AF не определён, ZF, PF, PF флажок знака и паритета определяется результатами команды.

  `and OP1, OP2` -- содержимое OP1 логически умножается на OP2, результат посылается по адресу
  первого оперенда.

  Пример:

  ```
  ; (AL) = 1011 0011
  ; (DL) = 0000 1111
  and AL, DL
  ; (AL) = 0000 0011
  ```

  Второй операнд называют *маской*. Установка в ноль заданных разрядов первого операнда.
  Нулевые разряды маски обнуляют соотвествующие разряды первого операнда. Единичные
  оставляют их неизменными.

  Маску можно указывать непосредственно в команде, можно хранить в регистре или памяти.
  То есть могут использоваться различные виды адресации.

  Например:

  + `and CX, 0FFh`
  + `and AX, CX`
  + `and AX, TOT` -- маска содержится в ОЗУ по адресу (DS) + TOT
  + `and CX, TOT[BX+SI]` -- маска содержится в ОЗУ по адресу (DS) + (BX) + (SI) + TOT
  + `and TOT[BX+SI], CX` -- маска содержится в CX, мы обнуляем разряды в памяти по указанному адресу
  + `and CL, 0Fh` -- в ноль устанавливаются старшие 4 разряда регистра CL

+ *Логическое сложение*. `OR OP1, OP2`.

  Пример:

  ```
  ; (AL) = 1011 0011
  ; (DL) = 0000 1111
  or AL, DL
  ; (AL) = 1011 1111
  ```

  Второй операнд также называют *маской*. Она устанавливает некоторые разряды в единицы.

  Можно использовать различные способы адресации:
  + `or CX, 00FFh`
  + `or TAM, AL` -- установка каких-то разрядов в единицу в памяти
  + `or TAM[BX][DX], CX`

  Если все разряды окажутся равными 0, то ZF = 1

+ *Исключающее или*. `XOR OP1, OP2`.

  ```
  ; (AL) = 1011 0011
  ; (DL) = 0000 1111
  xor AL, DL
  ; (AL) = 1011 1100
  ```

+ *Логическое отрицание*. `NOT OP1`

  Изменяет содержимое операнда на противоположное. Происходит инверсия разрядов.
  Эта команда не меняет значения флажков.

== Особенности

+ `XOR AX, AX` -- обнуляет регистр AX быстрее, чем команда `MOV AX, 0` или `SUB AX, 0`
+ ```
  XOR AX, BX
  XOR BX, AX
  XOR AX, BX
  ```

  Эти три команды выполнятся быстрее, чем `XCHG AX, BX`

  Пусть в группе 20 человек.

  `X DB 20 DUP (?)`. Каждый студент сдаёт 4 экзамена. Оценка за экзамен: 1 -- сдано, 0 -- не сдано.
  В `DL` сохраним число задолжников.

  ```
  -----/-----
  mov DL, 0
  mov SI, 0      ; i = 0
  mov CX, 20     ; кол-во повторений цикла
  nz:
    mov AL, X[SI]
    and AL, 0Fh  ; обнуляем старшую часть байта
    xor AL, OFh
    jz m         ; ZF = 1, хвостов нет, передаём на повторение цикла
    inc DL       ; увеличиваем количество задолжников
  m:
    inc SI       ; переходим к следующему студенту
    loop nz
    add DL, "0"
    mov AH, 6
    int 21h
  -----/-----
  ```

== Команды сдвига

Формат команд арифметического и логического сдвига можно представить так:

```
sXY OP1, OP2
```

+ `X` -- `h` или `a`
+ `Y` -- `l` или `r`
+ `OP1` -- `r` или `m`
+ `OP2` -- `d` или `CL` (если `CL`, то от 0 до 31)

+ `shl` -- логический сдвиг влево
+ `shr` -- логический сдвиг вправо
+ `sal` -- арифметический сдвиг влево (не отличается от логического влево)
+ `sar` -- арифметический сдвиг вправо (отличается от логического вправо тем, что освободившийся разряд
  заполняется старшим разрядом)

*TODO: прикрепить фотографию*

Пример:

```
; (AL) = 1101 0101
sar AL, 1
; (AL) = 1110 1010 и CF = 1
```

Сдвиги больше, чем на 1, то же самое, что последовательно сдвинуть на 1 несколько раз.

Сдвиги *повышенной точности* для i186 и выше:

```
shrd OP1, OP2, OP3
shld OP2, OP2, OP3
```

Содержимое OP1 сдвигается соответственно влево или вправо на OP3 разрядов, но вышедшие за
разрядную сетку биты не обнуляются, а заполняются содержимым OP2 (им может быть только регистр).

Также существуют *циклические сдвиги*:

```
rol OP1, OP2
ror OP1, OP2
```

*TODO: прикрепить фотографию*

Также есть циклические сдвиги, в котором участвует флажок:

```
rcl OP1, OP2
rcr OP1, OP2
```

*TODO: прикрепить фотографию*

При выполнении циклического сдвига значение флажка `CF` равно последнему биту, вышедшему за
пределы сдвигаемого операнда.

При командах сдвига ZF, SF, PF устанавливаются в соответствии с результатом сдвига.
AF не определён. OF не определён при сдвигах на несколько разрядов, при сдвиге на 1 разряд
в зависимости от команды:
+ Для циклических команд, повышенной точности и `sal`, `shl` флаг OF = 1, если после сдвига
  старший бит изменился
+ После `sar` флаг OF = 0
+ После `shr` флаг OF = значению старшего бита исходного числа

*На самостоятельное изучение* команды BT, BTS, BTR, BTC, BTF, BSR.

== Команды BT, BTS, BTR, BTC, BSF, BSR

+ Команда ```nasm BT <приёмник>, <источник>```

  Проверяет значение бита в приёмнике, установленного в истонике. Результат
  записывает в `CF`.

  Пример

  ```nasm
  BT AX, 3  ; Проверяет 3-й бит в AX, записывает его значение в CF
  ```
+ Команда ```nasm BTS <приёмник>, <источник>```

  Аналогично `BT`, но устанавливает указанный бит в значение единицы.

+ Команда ```nasm BTR <приёмник>, <источник>```

  Аналогично `BT`, но устанавливает указанный бит в значение нуля.

+ Команда ```nasm BTC <приёмник>, <источник>```

  Аналогично `BT`, но инвертирует указанный бит.

+ Команда ```nasm BSF <приёмник>, <источник>```

  Сканирует источник от младшего бита к старшему, пока не встретит бит в значении единицы.
  После этого записывает его номер в источник.

+ Команда ```nasm BSR <приёмник>, <источник>```

  Аналогично `BSF`, но сканирует от старшего бита к младшему.
