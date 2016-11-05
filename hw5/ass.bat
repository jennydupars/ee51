asm86 keypad.asm m1 db ep
asm86 handlers.asm m1 db ep
asm86 main.asm m1 db ep
asm86 tmrsetup.asm m1 db ep
asm86 initcs.asm m1 db ep 
link86 main.obj, hw5test.obj, keypad.obj, tmrsetup.obj, initcs.obj, handlers.obj to hw5.lnk
loc86 hw5.lnk NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))
pcdebug