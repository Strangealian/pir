DEF:
    LOOPTAG EQU 60H;次数统计保存地址
    LOOPTIME EQU 59H;延时循环次数保存地址
    OFFSET1 EQU 58H;个位偏移地址记录
    OFFSET2 EQU 57H;十位偏移地址记录
    BALANCE EQU 56H;负载 均衡标记
    DEFAULTDT EQU 55H;;
    THT EQU 0D8H;计数器高字节
    TLT EQU 0F0H;计数器低字节

    KEYBUF1 EQU 54H;键盘读入数据十位
    KEYBUF2 EQU 53H;键盘读入数据个位；
    KEYBUF3 EQU 52H;
    ADJUSTFLAG EQU 51H;

    ORG 0000H;
    AJMP MAIN;
    ORG 000BH;T0溢出中断入口地址
    AJMP DELAY;
    ORG 0013H;
    AJMP KBSCN;
    ORG 0060H;
    ;!!!!JNZ需要更改 JNZ 是为了测试


MAIN:
    MOV SP,#60H;
    
    MOV OFFSET1,#0AH;
    MOV OFFSET2,#03H;
    MOV DEFAULTDT,#30;
    MOV LOOPTIME,#05H;
    MOV ADJUSTFLAG,#1;
    MOV KEYBUF2,#00H;
    SETB EA;
	SETB EX1;
	SETB IT1;
    /*外部中断1最高优先级*/
    SETB PX1;
    LOOP:
        MOV LOOPTAG,#00H;
        MOV BALANCE,#0FFH;
        MOV ADJUSTFLAG,#1;

        MOV P1,#0FFH;p1为数据输出，点亮LED用
        MOV P0,#0FFH;
        MOV P3,#0FH;p3为键盘输入口
        MOV P2,#0FFH;p2作为数据输入口


        MOV A,P2;
        ANL A,#07H; 0  截取三位输入信号，只有输入信号是0，2，4才点亮
        MOV R7,A;暂存
        JNZ LIGHT;
        ANL A,#05H;如果不是0则截取出三位，与101，如果为0说明为2；点亮
        JNZ LIGHT;
        MOV A,R7;如果不是0 恢复A里面的数据
        ANL A,#03H;如果也不是2，与011，如果为0说明为4，点亮
        JNZ LIGHT;
        AJMP LOOP;

    LIGHT:
        CPL P1.0;
        NOP;
        NOP;
        MOV R5,DEFAULTDT;
        MOV R2,OFFSET2;存放数码管十位对应偏移地址
        MOV A,ADJUSTFLAG;
        CJNE A,#0,ADJUST;
        MOV R3,OFFSET1;存放数码管个位对应偏移地址
        
        AJMP LIGHTTIME;
        ADJUST:
            MOV A,KEYBUF2;
            CJNE A,#00H,ADJUST1;
            MOV R3,OFFSET1;
            AJMP LIGHTTIME;
            ADJUST1:
            MOV R3,A;
            MOV ADJUSTFLAG,#0;

        LIGHTTIME:
            LCALL DELAY1S;延时1s后数码管显示相应数字
            DEC R3;
            MOV A,#00H;
            CJNE A,03H,CFG;
            DEC R2;
        CFG:
            CJNE R3,#00H,ASGTO;
            MOV R3,OFFSET1;
        ASGTO:
            DJNZ R5,LIGHTTIME;
            CPL P1.0;
            AJMP LOOP;

;延时1s子程序
DELAY1S:
        PUSH PSW;
        PUSH ACC;
        AJMP DELAY50MS;
    ;延时50ms子程序 65536-50000=15536=3CB0
    DELAY50MS:
        MOV TMOD,#01H;计数器1工作于方式1
        MOV TH0,#THT;加一计数器高字节
        MOV TL0,#TLT;加一计数器低字节
        SETB EA;
        SETB TR0;
        SETB ET0;
        
    TIMEOUT:  
    

        MOV R6,LOOPTAG;

        CJNE R6,#64H,TIMEOUT;
        MOV LOOPTAG,#00H;
        POP ACC;
        POP PSW;
        RET;





DELAY:;计数器1溢出中断出口
        PUSH PSW;
        PUSH ACC;
        MOV R6,LOOPTAG;
        INC R6;
        MOV LOOPTAG,R6;
        MOV TH0,#THT;加一计数器高字节
        MOV TL0,#TLT;加一计数器低字节

        
        ;点亮数码管
    NUMDIS:
    
        
        MOV A,R6;
        ANL A,#01H;
        MOV BALANCE,A;负载均衡
        JNZ BAL2;
    BAL1:
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
        MOV P0,#00H;
        MOV P0,A;
        MOV A,BALANCE;
        JNZ BAL3;
        ;LCALL PWNWAT;延时1ms
        ;LCALL PWNWAT;
        
    BAL2:
        MOV R4,#0FEH;
    
        MOV DPTR, #TIMETAB;
        MOV A,R2;
        MOVC A,@A+DPTR;
        ;CALL PWNWAT;
        CLR P2.6;
        SETB P2.7;
        ;MOV P0,#0FFH;
        MOV P0,R4;
        CLR P2.7;
        SETB P2.6;
        MOV P0,#00H;
        MOV P0,A;
        MOV A,BALANCE;
        JNZ BAL1;
        ;LCALL PWNWAT;
    BAL3:
        CJNE R6,#64H,BREAK;
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



/*1号中断入口
*键盘响应
*/
KBSCN:

        CPL P1.7;
        MOV KEYBUF1,#03H;
        MOV KEYBUF2,#00H;
        MOV DEFAULTDT,#30;
        /*进入中断等待按键释放*/
    WAT4RLS:;WAITE FOR REALSE
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JNZ WAT4RLS;



        PUSH PSW;
        PUSH ACC;
        SETB RS0;USE THE SECOND SET OF REGISTERS;
        CLR IT1;
        MOV R1,#0;R1用作标志，用来标记数据应该存入哪个buf。
    KBSCNR1:
        MOV P3,#0FFH;
        CLR P3.4;
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JZ KBSCNR2;
        CALL DELAY4KBD;

        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JZ KBSCNR2;
    C11:
        NOP;
    C12:
        NOP;
    C13:
        NOP;
    C14:
        NOP;

    WAT4RLS1:;WAITE FOR REALSE
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JNZ WAT4RLS1;

    KBSCNR2:
        MOV P3,#0FFH;
        CLR P3.5;
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JZ KBSCNR3;
        CALL DELAY4KBD;

        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JZ KBSCNR3;

    C21:
        CJNE A,#01H,C22;0001左上角被按下
        CJNE R1,#0,C21BUF2;
        MOV KEYBUF1,#07H;
        CPL P1.0;
        MOV R1,#1;
        AJMP WAT4RLS2;
    C21BUF2:
        MOV KEYBUF2,#07H;
        MOV R1,#0;
        AJMP WAT4RLS2;
    C22:
        CJNE A,#02H,C23;
        CJNE R1,#0,C22BUF2;
        MOV KEYBUF1,#04H;
        MOV R1,#1;
        AJMP WAT4RLS2;
    C22BUF2:
        MOV KEYBUF2,#04H;
        MOV R1,#0;
        AJMP WAT4RLS2;
    C23:
        CJNE A,#04H,C24;
        CJNE R1,#0,C23BUF2;
        MOV KEYBUF1,#01H;
        MOV R1,#1;
        AJMP WAT4RLS2;
    C23BUF2:
        MOV KEYBUF2,#01H;
        MOV R1,#0;
        AJMP WAT4RLS2;
    C24:
        CJNE A,#08H,WAT4RLS2;
        ;MOV KEYBUF1,#0FFH;
        AJMP EXITSET;

    WAT4RLS2:;WAITE FOR REALSE
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JNZ WAT4RLS2;




    KBSCNR3:
        MOV P3,#0FFH;
        CLR P3.6;
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JZ KBSCNR4;
        CALL DELAY4KBD;

        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JZ KBSCNR4;

    C31:
        CJNE A,#01H,C32;0001左上角被按下
        CJNE R1,#0,C31BUF2;
        MOV KEYBUF1,#08H;
        MOV R1,#1;
        AJMP WAT4RLS3;
    C31BUF2:
        MOV KEYBUF2,#08H;
        MOV R1,#0;
        AJMP WAT4RLS3;
    C32:
        CJNE A,#02H,C33;
        CJNE R1,#0,C32BUF2;
        MOV KEYBUF1,#05H;
        MOV R1,#1;
        AJMP WAT4RLS3;
    C32BUF2:
        MOV KEYBUF2,#05H;
        MOV R1,#0;
        AJMP WAT4RLS3;
    C33:
        CJNE A,#04H,C34;
        CJNE R1,#0,C33BUF2;
        MOV KEYBUF1,#02H;
        MOV R1,#1;
        AJMP WAT4RLS3;
    C33BUF2:
        MOV KEYBUF2,#02H;
        MOV R1,#0;
        AJMP WAT4RLS3;
    C34:
        CJNE A,#08H,WAT4RLS2;
        CJNE R1,#0,C34BUF2;
        MOV KEYBUF1,#00H;
        MOV R1,#1;
        AJMP WAT4RLS3;
    C34BUF2:
        MOV KEYBUF2,#00H;
        MOV R1,#0;

    WAT4RLS3:;WAITE FOR REALSE
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JNZ WAT4RLS3;

    KBSCNR4:
        MOV P3,#0FFH;
        CLR P3.7;
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JZ KBSCNEND;
        CALL DELAY4KBD;

        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JZ KBSCNEND;

    C41:
        CJNE A,#01H,C42;0001左上角被按下
        CJNE R1,#0,C41BUF2;
        MOV KEYBUF1,#09H;
        MOV R1,#1;
        AJMP WAT4RLS4;
    C41BUF2:
        MOV KEYBUF2,#09H;
        MOV R1,#0;
        AJMP WAT4RLS4;
    C42:
        CJNE A,#02H,C43;
        CJNE R1,#0,C42BUF2;
        MOV KEYBUF1,#06H;
        MOV R1,#1;
        AJMP WAT4RLS4;
    C42BUF2:
        MOV KEYBUF2,#06H;
        MOV R1,#0;
        AJMP WAT4RLS4;
    C43:
        CJNE A,#04H,C44;
        CJNE R1,#0,C43BUF2;
        MOV KEYBUF1,#03H;
        MOV R1,#1;
        AJMP WAT4RLS4;
    C43BUF2:
        MOV KEYBUF2,#03H;
        MOV R1,#0;
        AJMP WAT4RLS4;
    C44:
        CJNE A,#08H,WAT4RLS4;
        NOP;

    WAT4RLS4:;WAITE FOR REALSE
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JNZ WAT4RLS4;



    KBSCNEND:

        AJMP KBSCNR1;
    EXITSET:
        CPL P1.7;
        ;CPL P1.1;
    /*退出中断，等待键盘释放，*/
    WAT4EXIT:;WAITE FOR REALSE
        MOV A,P3;
        ANL A,#0FH;
        XRL A,#0FH;
        JNZ WAT4EXIT;

        /*需要设置offset1 offset2 第一组寄存器的R5，R5存放定时秒数
        *OFFSET1为个位，offset2为十位
        *buf2为个位，buf1为十位
        */

        MOV A,KEYBUF1;
        MOV B,#10;
        MUL AB;
        ADD A,KEYBUF2;
        MOV KEYBUF3,A;

        CLR RS0;USE THE DEFAULT SET OF REGISTERS;
        POP ACC;
        POP PSW;

        ;MOV OFFSET1,KEYBUF2;
        ;INC OFFSET1;
        MOV OFFSET2,KEYBUF1;
        INC OFFSET2;为什么要加1，因为存放数码管对应16进制的表最前面多加了一个00H;
        ;MOV R5,KEYBUF3;
        MOV DEFAULTDT,KEYBUF3;

        SETB IT1;
        MOV P3,#0FH;
        RETI;


    DELAY4KBD:
        MOV R6,#10
    D1:        
        MOV R7,#248
        DJNZ R7,$
        DJNZ R6,D1
        RET






/*废弃，未使用*/
PWNWAT: ;power on wait
        PUSH PSW;
        PUSH ACC;
        SETB RS0;
        MOV R1,#40;
        MOV R2,#10;
    PW1:
        NOP;
        NOP;
        DJNZ R1,PW1;
        MOV R1,#40;
        DJNZ R2,PW1;
        POP ACC;
        POP PSW;
        RET;


TIMETAB:
    DB 00H,3FH,06H,5BH;
    DB 4FH,66H,6DH,7DH;
    DB 07H,7FH,6FH;
    ;DB 6FH,7FH,07H,7DH;
    ;DB 6DH,66H,4FH,5BH;
    ;DB 06H,3FH;
END;