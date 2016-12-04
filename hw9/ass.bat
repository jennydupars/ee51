asm86 converts.asm m1 db ep
asm86 queue.asm m1 db ep
asm86 serial.asm m1 db ep
asm86 initcs.asm m1 db ep

asm86 segtab14.asm m1 db ep 
asm86 int2.asm m1 db ep 
asm86 intrpvec.asm m1 db ep 
asm86 tmrsetup.asm m1 db ep 

link86 converts.obj, queue.obj, serial.obj, initcs.obj, segtab14.obj, int2.obj, intrpvec.obj, tmrsetup.obj to setup9.lnk



asm86 evequeue.asm m1 db ep
asm86 remomain.asm m1 db ep 
asm86 remoteui.asm m1 db ep
asm86 display.asm m1 db ep 
asm86 keypad.asm m1 db ep 
link86 remomain.obj, remoteui.obj, display.obj, evequeue.obj, keypad.obj to hw9.lnk

link86 setup9.lnk, hw9.lnk to final.lnk
loc86 final.lnk NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))
pcdebug