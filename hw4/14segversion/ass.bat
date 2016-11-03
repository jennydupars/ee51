asm86 display.asm m1 db ep
asm86 converts.asm m1 db ep
asm86 evthndlr.asm m1 db ep
asm86 tmrhndlr.asm m1 db ep
asm86 segtab14.asm m1 db ep
asm86 main.asm m1 db ep
link86 main.obj, hw4test.obj, display.obj, converts.obj, evthndlr.obj, tmrhndlr.obj, segtab14.obj to hw4.lnk
loc86 hw4.lnk NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))
pcdebug