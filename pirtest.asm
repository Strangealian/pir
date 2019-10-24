LOOPTIME EQU 60H;
INITONE EQU 03H;

ORG 0000H;
AJMP MAIN;
ORG 000BH;T0溢出中断入口地址
AJMP DELAY;
ORG 0060H;
;!!!!JNZ需要更改 JNZ 是为了测试

MAIN:
MOV 60H,#00H;
    MOV P1,#0FFH;
    MOV P0,#0FFH;
    MOV P2,#0FFH;
	MOV A,P2;
    ANL A,#07H; 0  截取三位输入信号，只有输入信号是0，2，4才点亮
    MOV R7,A;暂存
    JNZ LIGHT;
    ANL A,#05H;如果不是0则截取出三位，与101，如果为0说明为2；点亮
    JNZ LIGHT;
    MOV A,R7;如果不是0 恢复A里面的数据
    ANL A,#03H;如果也不是2，与011，如果为0说明为4，点亮
    JNZ LIGHT;
    AJMP MAIN;

LIGHT:
    CPL P1.0;
    NOP;
	NOP;
    MOV A,#2;
    MOV DPTR,#TIMETAB;
    MOVC A,@A+DPTR;
    MOV R5,A;R5存放的数据为灯亮的秒数，通过查表得到
    MOV R2,#0AH;存放数码管十位对应偏移地址
    MOV R3,#03H;存放数码管个位对应偏移地址
LIGHTTIME:
    
    LCALL DELAY1S;延时1s后数码管显示相应数字
    INC R3;
    MOV A,#INITONE;
    ADD A,#10;
    CJNE A,03H,CFG;
    INC R2;
CFG:
    CJNE R3,#0DH,ASGTO;
    MOV R3,#03H;
ASGTO:
    DJNZ R5,LIGHTTIME;
	CPL P1.0;
    AJMP MAIN;




DELAY:;计数器1溢出中断出口
    PUSH PSW;
    PUSH ACC;
    MOV R6,60H;
    INC R6;
    MOV 60H,R6;
    MOV TH0,#0B1H;加一计数器高字节
    MOV TL0,#0E0H;加一计数器低字节

    
     ;点亮数码管
NUMDIS:
   
    
    MOV R4,#0FDH;R4存放数码管位置个位
    
    ;MOV R3,A;
    CLR P2.6;位选选中个位
    SETB P2.7;
    ;MOV P0,#0FFH;
    MOV P0,R4;
    CLR P2.7;

    MOV DPTR,#TIMETAB;
    MOV A,R3;
    MOVC A,@A+DPTR;查表得到相应数字对应值
    SETB P2.6;
    ;MOV P0,#00H;
    MOV P0,A;
    LCALL PWNWAT;延时1ms
    CLR P2.6;

    MOV R4,#0FEH;
   
    SETB P2.7;
    ;MOV P0,#0FFH;
    MOV P0,R4;
    CLR P2.7;


    MOV DPTR, #TIMETAB;
    MOV A,R2;
    MOVC A,@A+DPTR;
    SETB P2.6;
    ;MOV P0,#00H;
    MOV P0,A;
    LCALL PWNWAT;

    CJNE R6,#14H,BREAK;
    CLR P2.6;
	CLR ET1;
    CLR TR1;
    CLR EA;
    MOV TMOD,#00H;
	;MOV 60H,#00H;
    
BREAK:
	POP ACC;
    POP PSW;
   	RETI;

;延时1s子程序
DELAY1S:
    PUSH PSW;
    PUSH ACC;
    AJMP DELAY50MS;
;延时50ms子程序 65536-50000=15536=3CB0
DELAY50MS:
    MOV TMOD,#01H;计数器1工作于方式1
    MOV TH0,#0B1H;加一计数器高字节
    MOV TL0,#0E0H;加一计数器低字节
    SETB EA;
    SETB TR0;
    SETB ET0;
    
TIMEOUT:  
  

    MOV R6,60H;

    CJNE R6,#14H,TIMEOUT;
	;AJMP LIGHT;
    MOV 60H,#00H;
    POP ACC;
    POP PSW;
    RET;

PWNWAT: ;power on wait
    PUSH PSW;
    PUSH ACC;
    SETB RS0;
    MOV R1,#120;
    MOV R2,#80;
PW1:
    NOP;
    NOP;
    DJNZ R1,PW1;
    DJNZ R2,PW1;
    POP ACC;
    POP PSW;
    RET;


TIMETAB:
    DB 0AH,14H,1EH;定义灯亮的秒数10，20，30s
    ;DB 3FH,06H,5BH,4FH;
    ;DB 66H,6DH,7DH,07H;
    ;DB 7FH,6FH;
    DB 6FH,7FH,07H,7DH;
    DB 6DH,66H,4FH,5BH;
    DB 06H,3FH;
END;