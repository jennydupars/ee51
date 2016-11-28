
asm86 main.asm m1 db ep
asm86 parse.asm m1 db ep 
link86 main.obj, parse.obj, hw8test.obj to hw8.lnk
loc86 hw8.lnk NOIC AD(SM(CODE(4000H),DATA(400H),STACK(7000H)))
pcdebug -s115200