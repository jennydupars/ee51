asm86 motors.asm m1 db ep
asm86 trigtbl.asm m1 db ep
asm86 main.asm m1 db ep
asm86 tmrsetup.asm m1 db ep
asm86 handlers.asm m1 db ep
asm86 initcs.asm m1 db ep 
asm86 initpp.asm m1 db ep 
link86 main.obj, motors.obj, hw6test.obj, trigtbl.obj, initpp.obj, tmrsetup.obj, initcs.obj, handlers.obj to hw6.lnk
loc86 hw6.lnk NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))
pcdebug