asm86 queue.asm m1 db ep
asm86 main.asm m1 db ep
link86 main.obj, hw3test.obj, queue.obj to hw3.lnk
loc86 hw3.lnk NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))
pcdebug