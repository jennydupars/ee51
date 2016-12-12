REM 	Since we have more than 8 files, we will have to link the files more than 
REM 	2 times to link all the files together. The following files are linked 
REM 	together to create a working remote unit: 
REM 		converts.asm - converts numbers to decimal and hex string representations
REM 		queue.asm - provides queue routines for queues used in the program 
REM 		serial.asm - routines for using serial channel input/output/error handling
REM 		initcs.asm - initialize chip selects for the 80188
REM 		initpp.asm - initialize parallel ports for motors
REM 		int2.asm - INT2 interrupt setup and handler 
REM			intrpvec.asm - sets up illegal interrupt handler 
REM 		tmrsetup.asm - sets up timer 0 interrupts and handlers 
REM 		trigtbl.asm - trigonometry table for looking up Sine and Cosine 
REM 		evequeue.asm - routines for managing event queue 
REM			robomain.asm - main loop for motors unit 
REM 		roboui.asm - motors unit user interface/event handling functions 
REM 		parse.asm - parsing finite state machine for handling commands to motors
REM 		motors.asm  - motors routines to update motors and laser operation

asm86 converts.asm m1 db ep
asm86 queue.asm m1 db ep
asm86 serial.asm m1 db ep
asm86 initcs.asm m1 db ep

asm86 initpp.asm m1 db ep 
asm86 int2.asm m1 db ep 
asm86 intrpvec.asm m1 db ep 
asm86 tmrsetup.asm m1 db ep 

REM 	Now we link all these files: 
link86 converts.obj, queue.obj, serial.obj, initcs.obj, initpp.obj, int2.obj, intrpvec.obj, tmrsetup.obj to setup10.lnk



asm86 trigtbl.asm m1 db ep
asm86 evequeue.asm m1 db ep
asm86 robomain.asm m1 db ep 
asm86 roboui.asm m1 db ep
asm86 parse.asm m1 db ep 
asm86 motors.asm m1 db ep 

REM 	Now we will link these files:
link86 robomain.obj, roboui.obj, evequeue.obj, parse.obj, trigtbl.obj, motors.obj to func10.lnk

REM 	Link the two sets of files:
link86 setup10.lnk, func10.lnk to hw10.lnk

REM 	Initialize locations
loc86 hw10.lnk NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))

REM 	Open pcdebug with a faster baud rate
pcdebug -s115200 -r