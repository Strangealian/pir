LOOPTIME EQU 60H;


ORG 0000H;
AJMP MAIN;
ORG 001BH;T0溢出中断入口地址
AJMP DELAY;
ORG 0060H;
;!!!!JNZ需要更改 JNZ 是为了测试

MAIN:
MOV 60H,#00H;
    MOV P1,#0FFH;
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
    MOV A,#0;
    MOV DPTR,#TIMETAB;
    MOVC A,@A+DPTR;
    MOV R5,A;R5存放的数据为灯亮的秒数，通过查表得到

    ;点亮数码管
NUMDIS:
    MOV R4,#0FEH;先设置十位
    CLR P2.6;
    SETB P2.7;
    MOV P0,R4;

    MOV DPTR,#TIMETAB;
    MOV A,#04H;
    MOVC A,@A+DPTR;查表得到相应数字对应值
    CLR P2.7;
    SETB P2.6;
    MOV P0,A;
    CLR P2.6;

    MOV R4,#0FDH;R4存放数码管位置个位
    
    ;MOV R3,A;
    CLR P2.6;设置选中个位
    SETB P2.7;
    MOV P0,R4;

    MOV R3,#03H;存放数码管对应偏移地址
LIGHTTIME:
    LCALL DELAY1S;延时1s后数码管显示相应数字
    CPL P1.1;
	CPL P1.0;

    MOV DPTR,#TIMETAB;
    MOV A,R3;
    MOVC A,@A+DPTR;查表得到相应数字对于值
    CLR P2.7;
    SETB P2.6;
    MOV P0,A;
    INC R3;

    DJNZ R5,LIGHTTIME;
	CPL P1.0;
   
    AJMP MAIN;



;延时1s子程序
DELAY1S:
    PUSH PSW;
    PUSH ACC;
    AJMP DELAY50MS;
DELAY:
    PUSH PSW;
    PUSH ACC;
    MOV R6,60H;
    INC R6;
    MOV 60H,R6;
    MOV TH0,#1BH;加一计数器高字节
    MOV TL0,#5EH;加一计数器低字节
    CJNE R6,#14H,BREAK;
	CLR ET1;
    CLR TR1;
    CLR EA;
    MOV TMOD,#00H;
	;MOV 60H,#00H;
    
BREAK:
	POP ACC;
    POP PSW;
   	RETI;

;延时50ms子程序 65536-50000=15536=1B5E
DELAY50MS:
    MOV TMOD,#10H;计数器0工作于方式1
    MOV TH0,#1BH;加一计数器高字节
    MOV TL0,#5EH;加一计数器低字节
    SETB EA;
    SETB TR1;
    SETB ET1;
    
TIMEOUT:  
    MOV R6,60H;
    CJNE R6,#14H,TIMEOUT;
	;AJMP LIGHT;
    MOV 60H,#00H;
    POP ACC;
    POP PSW;
    RET;




TIMETAB:
    DB 03H,14H,1EH;定义灯亮的秒数10，20，30s
    DB 3FH,06H,5BH,4FH;
    DB 66H,6DH,7DH,07H;
    DB 7FH,6FH;
END;