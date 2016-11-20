asm86 serialio.asm m1 db ep
asm86 main.asm m1 db ep
asm86 handlers.asm m1 db ep
asm86 initcs.asm m1 db ep 
asm86 queue.asm m1 db ep 
asm86 int2.asm m1 db ep 
link86 main.obj, handlers.obj, queue.obj, initcs.obj, int2.obj, hw7test.obj, serialio.obj to hw7.lnk
loc86 hw7.lnk NOIC AD(SM(CODE(4000H),DATA(400H),STACK(7000H)))
pcdebug