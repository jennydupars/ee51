REM 	Since we have more than 8 files, we will have to link the files more than 
REM 	2 times to link all the files together. The following files are linked 
REM 	together to create a working remote unit: 
REM 		converts.asm - converts numbers to decimal and hex string representations
REM 		queue.asm - provides queue routines for queues used in the program 
REM 		serial.asm - routines for using serial channel input/output/error handling
REM 		initcs.asm - initialize chip selects for the 80188
REM 		segtab14.asm - table holding 14-segment patterns for LED display 
REM 		int2.asm - INT2 interrupt setup and handler 
REM			intrpvec.asm - sets up illegal interrupt handler 
REM 		tmrsetup.asm - sets up timer 0 interrupts and handlers 
REM 		evequeue.asm - routines for managing event queue 
REM			remomain.asm - main loop for remote unit 
REM 		remoteui.asm - remote unit user interface/event handling functions 
REM 		display.asm - display routines to control LED display 
REM 		keypad.asm  - keypad routines to detect and handle key presses 


asm86 converts.asm m1 db ep
asm86 queue.asm m1 db ep
asm86 serial.asm m1 db ep
asm86 initcs.asm m1 db ep

asm86 segtab14.asm m1 db ep 
asm86 int2.asm m1 db ep 
asm86 intrpvec.asm m1 db ep 
asm86 tmrsetup.asm m1 db ep 

REM 	Link 8 files together into setup9.lnk :
link86 converts.obj, queue.obj, serial.obj, initcs.obj, segtab14.obj, int2.obj, intrpvec.obj, tmrsetup.obj to setup9.lnk


asm86 evequeue.asm m1 db ep
asm86 remomain.asm m1 db ep 
asm86 remoteui.asm m1 db ep
asm86 display.asm m1 db ep 
asm86 keypad.asm m1 db ep 

REM 	Link the remaining 5 files together into func9.lnk: 
link86 remomain.obj, remoteui.obj, display.obj, evequeue.obj, keypad.obj to func9.lnk

REM 	Link the 2 sets of files together into one object:
link86 setup9.lnk, func9.lnk to hw9.lnk

REM 	Set up segment locations: 
loc86 hw9.lnk NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))

REM 	Open pcdebug with reset mode on and open in serial com2 
pcdebug -r -p com2