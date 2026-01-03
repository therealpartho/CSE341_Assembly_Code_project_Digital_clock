include 'emu8086.inc'
ORG 100h

.DATA
    
    HOUR        DW 0
    MINUTE      DW 0
    SECOND      DW 0
    OLD_SECOND  DW 0     
    USE_SYSTEM_TIME DB 1 
    
    
    CLOCK_PAUSED DB 0    
    
    
    FORMAT_12H  DB 0     
    AM_PM       DB 'AM', 0 
    
    
    ALARM_HOUR  DW 0
    ALARM_MIN   DW 0
    ALARM_SEC   DW 0
    ALARM_SET   DB 0     
    ALARM_STATUS DB 0    
    
    
    TIME_MSG    DB 'Current Time: ', 0
    ALARM_MSG   DB 'Alarm Time  : ', 0
    ALARM_RING  DB 13, 10, '* ALARM! ALARM! ALARM! *', 13, 10, 0
    INST_MSG    DB 13, 10, 'Controls:', 13, 10
                DB '  T - Get system time', 13, 10
                DB '  A - Set alarm', 13, 10
                DB '  S - Set time manually', 13, 10
                DB '  P - Pause/Resume clock', 13, 10
                DB '  F - Toggle 12/24 hour format', 13, 10
                DB '  Q - Quit program', 13, 10, 0
    
    
    PROMPT_HOUR    DB  'Enter hour (0-23): ', 0
    PROMPT_MIN     DB  'Enter minute (0-59): ', 0
    PROMPT_SEC     DB  'Enter second (0-59): ', 0
    ALARM_SET_MSG  DB  13, 10, 'Alarm has been set!', 13, 10, 0
    TIME_SET_MSG   DB  13, 10, 'Time has been set!', 13, 10, 0
    
    
    FORMAT_12H_MSG DB  13, 10, 'Switched to 12-hour format', 13, 10, 0
    FORMAT_24H_MSG DB  13, 10, 'Switched to 24-hour format', 13, 10, 0
    
    
    CLOCK_PAUSED_MSG DB  13, 10, 'Clock PAUSED', 13, 10, 0
    CLOCK_RESUMED_MSG DB 13, 10, 'Clock RESUMED', 13, 10, 0
    
    
    FMT_TIME    DB  '  :  :  ', 0
    
    
    STATUS_MSG  DB '                ', 0    
    
.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    
    CALL CLEAR_SCREEN
    
    
    CALL GET_SYSTEM_TIME
    
    
    LEA SI, INST_MSG
    CALL PRINT_STRING
    
MAIN_LOOP:
    
    CALL DISPLAY_TIME
    
    
    CMP ALARM_SET, 1
    JNE CHECK_INPUT
    CALL DISPLAY_ALARM
    
    
    CMP CLOCK_PAUSED, 1
    JNE CHECK_INPUT
    GOTOXY 0, 3
    PRINT '[PAUSED]'
    
CHECK_INPUT:
    
    MOV AH, 01h
    INT 16h
    JZ UPDATE_TIME  
    
    
    MOV AH, 00h
    INT 16h
    
    
    CMP AL, 't'     
    JE GET_SYS_TIME
    CMP AL, 'T'
    JE GET_SYS_TIME
    
    CMP AL, 'a'     
    JE SET_ALARM
    CMP AL, 'A'
    JE SET_ALARM
    
    CMP AL, 's'     
    JE SET_TIME
    CMP AL, 'S'
    JE SET_TIME
    
    CMP AL, 'p'     
    JE TOGGLE_PAUSE
    CMP AL, 'P'
    JE TOGGLE_PAUSE
    
    CMP AL, 'f'     
    JE TOGGLE_FORMAT
    CMP AL, 'F'
    JE TOGGLE_FORMAT
    
    CMP AL, 'q'     
    JE EXIT_PROGRAM
    CMP AL, 'Q'
    JE EXIT_PROGRAM
    
    JMP UPDATE_TIME
    
GET_SYS_TIME:
    CALL GET_SYSTEM_TIME
    MOV USE_SYSTEM_TIME, 1  ; Set flag to use system time
    JMP MAIN_LOOP
    
SET_ALARM:
    CALL SET_ALARM_TIME
    JMP MAIN_LOOP
    
SET_TIME:
    CALL SET_MANUAL_TIME
    JMP MAIN_LOOP
    
TOGGLE_PAUSE:
    CALL TOGGLE_CLOCK_PAUSE
    JMP MAIN_LOOP
    
TOGGLE_FORMAT:
    CALL TOGGLE_TIME_FORMAT
    JMP MAIN_LOOP
    
UPDATE_TIME:
   
    CMP CLOCK_PAUSED, 1
    JE CONTINUE_MAIN    
    CALL UPDATE_CLOCK
    
    
    CMP ALARM_SET, 1
    JNE CONTINUE_MAIN
    CALL CHECK_ALARM
    
CONTINUE_MAIN:
    
    MOV CX, 1
    MOV DX, 0
    MOV AH, 86H
    INT 15H
    
    JMP MAIN_LOOP
    
EXIT_PROGRAM:
    MOV AX, 4C00H
    INT 21H
MAIN ENDP


GET_SYSTEM_TIME PROC
    PUSH AX
    PUSH CX
    PUSH DX
    
    
    MOV AH, 2CH
    INT 21H
    
    
    
    XOR AX, AX
    MOV AL, CH
    MOV HOUR, AX
    
    XOR AX, AX
    MOV AL, CL
    MOV MINUTE, AX
    
    XOR AX, AX
    MOV AL, DH
    MOV SECOND, AX
    MOV OLD_SECOND, AX
    
    POP DX
    POP CX
    POP AX
    RET
GET_SYSTEM_TIME ENDP


UPDATE_CLOCK PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    
    CMP USE_SYSTEM_TIME, 1
    JNE UPDATE_MANUAL_TIME
    
   
    MOV AH, 2CH
    INT 21H
    
    
    XOR AX, AX
    MOV AL, DH
    CMP AX, OLD_SECOND
    JE NO_TIME_CHANGE
    
   
    MOV SECOND, AX
    MOV OLD_SECOND, AX
    
    
    XOR AX, AX
    MOV AL, CL
    MOV MINUTE, AX
    
    XOR AX, AX
    MOV AL, CH
    MOV HOUR, AX
    JMP NO_TIME_CHANGE
    
UPDATE_MANUAL_TIME:
    
    MOV AH, 2CH
    INT 21H
    
    
    XOR AX, AX
    MOV AL, DH
    CMP AX, OLD_SECOND
    JE NO_TIME_CHANGE
    
    
    MOV OLD_SECOND, AX
    
    
    INC SECOND
    CMP SECOND, 60
    JL NO_TIME_CHANGE
    
    
    MOV SECOND, 0
    INC MINUTE
    CMP MINUTE, 60
    JL NO_TIME_CHANGE
    
    
    MOV MINUTE, 0
    INC HOUR
    CMP HOUR, 24
    JL NO_TIME_CHANGE
    
    
    MOV HOUR, 0
    
NO_TIME_CHANGE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UPDATE_CLOCK ENDP


DISPLAY_TIME PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
  
    GOTOXY 0, 1
    LEA SI, TIME_MSG
    CALL PRINT_STRING
    
    
    CMP FORMAT_12H, 1
    JE DISPLAY_12H_FORMAT
    
    
    MOV AX, HOUR
    CALL PRINT_2DIGITS
    
    
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    
   
    MOV AX, MINUTE
    CALL PRINT_2DIGITS
    
   
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    
   
    MOV AX, SECOND
    CALL PRINT_2DIGITS
    
    JMP DISPLAY_TIME_DONE
    
DISPLAY_12H_FORMAT:
    
    CALL CONVERT_TO_12H_FORMAT
    CALL PRINT_2DIGITS
    
   
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    
   
    MOV AX, MINUTE
    CALL PRINT_2DIGITS
    
    
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    
    
    MOV AX, SECOND
    CALL PRINT_2DIGITS
    
    
    MOV DL, ' '
    MOV AH, 2
    INT 21H
    
  
    MOV SI, OFFSET AM_PM
    CALL PRINT_STRING
    
DISPLAY_TIME_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY_TIME ENDP


DISPLAY_ALARM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    
    GOTOXY 0, 2
    LEA SI, ALARM_MSG
    CALL PRINT_STRING
    
   
    CMP FORMAT_12H, 1
    JE DISPLAY_ALARM_12H
    
   
    MOV AX, ALARM_HOUR
    CALL PRINT_2DIGITS
    
   
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    
   
    MOV AX, ALARM_MIN
    CALL PRINT_2DIGITS
    
   
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    
    
    MOV AX, ALARM_SEC
    CALL PRINT_2DIGITS
    
    JMP DISPLAY_ALARM_DONE
    
DISPLAY_ALARM_12H:
    
    PUSH HOUR        
    MOV AX, ALARM_HOUR
    MOV HOUR, AX     
    CALL CONVERT_TO_12H_FORMAT
    CALL PRINT_2DIGITS
    POP HOUR        
    
    
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    
    MOV AX, ALARM_MIN
    CALL PRINT_2DIGITS
    
    
    MOV DL, ':'
    MOV AH, 2
    INT 21H
    
   
    MOV AX, ALARM_SEC
    CALL PRINT_2DIGITS
    
    
    MOV DL, ' '
    MOV AH, 2
    INT 21H
    
    
    CMP ALARM_HOUR, 12
    JAE ALARM_PM
    
    
    PRINT 'AM'
    JMP DISPLAY_ALARM_DONE
    
ALARM_PM:
   
    PRINT 'PM'
    
DISPLAY_ALARM_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY_ALARM ENDP


SET_ALARM_TIME PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
   
    CALL CLEAR_INPUT_AREA
    

    GOTOXY 0, 15
    LEA SI, PROMPT_HOUR
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV ALARM_HOUR, CX
    
   
    GOTOXY 0, 16
    LEA SI, PROMPT_MIN
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV ALARM_MIN, CX
    
   
    GOTOXY 0, 17
    LEA SI, PROMPT_SEC
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV ALARM_SEC, CX
    
   
    MOV ALARM_SET, 1
    
    
    GOTOXY 0, 18
    LEA SI, ALARM_SET_MSG
    CALL PRINT_STRING
    
    
    MOV CX, 0FH
    MOV DX, 4240H
    MOV AH, 86H
    INT 15H
    
   
    CALL CLEAR_INPUT_AREA
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SET_ALARM_TIME ENDP


SET_MANUAL_TIME PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    
    CALL CLEAR_INPUT_AREA
    
 
    GOTOXY 0, 15
    LEA SI, PROMPT_HOUR
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV HOUR, CX
    
   
    GOTOXY 0, 16
    LEA SI, PROMPT_MIN
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV MINUTE, CX
    
   
    GOTOXY 0, 17
    LEA SI, PROMPT_SEC
    CALL PRINT_STRING
    CALL SCAN_NUM
    MOV SECOND, CX
    
    
    MOV AH, 2CH
    INT 21H
    XOR AX, AX
    MOV AL, DH
    MOV OLD_SECOND, AX
    
 
    MOV USE_SYSTEM_TIME, 0
    
  
    GOTOXY 0, 18
    LEA SI, TIME_SET_MSG
    CALL PRINT_STRING
    
   
    MOV CX, 0FH
    MOV DX, 4240H
    MOV AH, 86H
    INT 15H
    
    CALL CLEAR_INPUT_AREA
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SET_MANUAL_TIME ENDP


TOGGLE_TIME_FORMAT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CALL CLEAR_INPUT_AREA
    
   
    CMP FORMAT_12H, 0
    JE SET_12H_FORMAT
    
   
    MOV FORMAT_12H, 0
    
    
    GOTOXY 0, 15
    LEA SI, FORMAT_24H_MSG
    CALL PRINT_STRING
    JMP FORMAT_TOGGLE_DONE
    
SET_12H_FORMAT:
   
    MOV FORMAT_12H, 1
    
    
    GOTOXY 0, 15
    LEA SI, FORMAT_12H_MSG
    CALL PRINT_STRING
    
    
    CALL UPDATE_AM_PM
    
FORMAT_TOGGLE_DONE:
   
    MOV CX, 0FH
    MOV DX, 4240H
    MOV AH, 86H
    INT 15H
    
    
    CALL CLEAR_INPUT_AREA
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
TOGGLE_TIME_FORMAT ENDP


UPDATE_AM_PM PROC
    PUSH AX
    
    
    CMP HOUR, 12
    JAE SET_PM
    
 
    MOV BYTE PTR [AM_PM], 'A'
    MOV BYTE PTR [AM_PM+1], 'M'
    JMP UPDATE_AM_PM_DONE
    
SET_PM:
   
    MOV BYTE PTR [AM_PM], 'P'
    MOV BYTE PTR [AM_PM+1], 'M'
    
UPDATE_AM_PM_DONE:
    POP AX
    RET
UPDATE_AM_PM ENDP


CONVERT_TO_12H_FORMAT PROC
    PUSH BX
    
    
    CALL UPDATE_AM_PM
    
    
    MOV AX, HOUR
    
    
    CMP AX, 0
    JNE CHECK_PM
    MOV AX, 12
    JMP CONVERT_DONE
    
CHECK_PM:
   
    CMP AX, 13
    JB CONVERT_DONE
    SUB AX, 12
    
CONVERT_DONE:
    POP BX
    RET
CONVERT_TO_12H_FORMAT ENDP


TOGGLE_CLOCK_PAUSE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
   
    CALL CLEAR_INPUT_AREA
    
   
    CMP CLOCK_PAUSED, 0
    JE PAUSE_CLOCK
    
   
    MOV CLOCK_PAUSED, 0
    
    
    GOTOXY 0, 15
    LEA SI, CLOCK_RESUMED_MSG
    CALL PRINT_STRING
    JMP PAUSE_TOGGLE_DONE
    
PAUSE_CLOCK:
   
    MOV CLOCK_PAUSED, 1
    
    
    GOTOXY 0, 15
    LEA SI, CLOCK_PAUSED_MSG
    CALL PRINT_STRING
    
PAUSE_TOGGLE_DONE:
    
    MOV CX, 0FH
    MOV DX, 4240H
    MOV AH, 86H
    INT 15H
    
    
    CALL CLEAR_INPUT_AREA
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
TOGGLE_CLOCK_PAUSE ENDP


CHECK_ALARM PROC
    PUSH AX
    
    
    CMP ALARM_STATUS, 1
    JE TRIGGER_ALARM_NOW
    
    
    MOV AX, HOUR
    CMP AX, ALARM_HOUR
    JNE NO_ALARM
    
    
    MOV AX, MINUTE
    CMP AX, ALARM_MIN
    JNE NO_ALARM
    
   
    MOV AX, SECOND
    CMP AX, ALARM_SEC
    JNE NO_ALARM
    
    
    MOV ALARM_STATUS, 1
    
TRIGGER_ALARM_NOW:
    
    MOV ALARM_STATUS, 0
    
    
    CALL TRIGGER_ALARM
    
NO_ALARM:
    POP AX
    RET
CHECK_ALARM ENDP


TRIGGER_ALARM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    
    PUSH DX
    
    
    CALL CLEAR_SCREEN
    
    
    MOV AH, 9
    MOV BH, 0
    MOV AL, ' '
    MOV CX, 2000 
    MOV BL, 01110000B  
    INT 10H
    
    
    GOTOXY 30, 10
    PRINT 'ALARM! ALARM! ALARM!'
    GOTOXY 30, 12
    PRINT 'Time matched: '
    
    
    GOTOXY 44, 12
    
    
    CMP FORMAT_12H, 1
    JNE ALARM_RING_24H
    
    
    PUSH HOUR        
    MOV AX, ALARM_HOUR
    MOV HOUR, AX     
    CALL CONVERT_TO_12H_FORMAT
    CALL PRINT_2DIGITS
    POP HOUR         
    
    PRINT ':'
    MOV AX, ALARM_MIN
    CALL PRINT_2DIGITS
    PRINT ':'
    MOV AX, ALARM_SEC
    CALL PRINT_2DIGITS
    PRINT ' '
    
    
    CMP ALARM_HOUR, 12
    JAE ALARM_RING_PM
    PRINT 'AM'
    JMP ALARM_RING_CONTINUE
    
ALARM_RING_PM:
    PRINT 'PM'
    JMP ALARM_RING_CONTINUE
    
ALARM_RING_24H:
    
    MOV AX, ALARM_HOUR
    CALL PRINT_2DIGITS
    PRINT ':'
    MOV AX, ALARM_MIN
    CALL PRINT_2DIGITS
    PRINT ':'
    MOV AX, ALARM_SEC
    CALL PRINT_2DIGITS
    
ALARM_RING_CONTINUE:
    GOTOXY 25, 14
    PRINT 'Press any key to dismiss the alarm...'
    
    
    MOV CX, 10
BEEP_LOOP:
    PUSH CX
    
    
    MOV AH, 2
    MOV DL, 7    
    INT 21H
    INT 21H      
    
    
    MOV CX, 3
    MOV DX, 0
    MOV AH, 86H
    INT 15H
    
    POP CX
    LOOP BEEP_LOOP
    
    
    MOV AH, 0
    INT 16H
    
    
    MOV ALARM_SET, 0
    
    
    POP DX
    CALL CLEAR_SCREEN
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
TRIGGER_ALARM ENDP


CLEAR_SCREEN PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AX, 0600H  
    MOV BH, 07H    
    MOV CX, 0000H  
    MOV DX, 184FH  
    INT 10H
    
    
    MOV AH, 2
    MOV BH, 0
    MOV DX, 0
    INT 10H
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CLEAR_SCREEN ENDP


CLEAR_INPUT_AREA PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AX, 0600H  
    MOV BH, 07H    
    MOV CX, 0F00H  
    MOV DX, 184FH  
    INT 10H
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CLEAR_INPUT_AREA ENDP


PRINT_2DIGITS PROC
    PUSH AX
    PUSH BX
    PUSH DX
    
    
    CMP AX, 10
    JAE PRINT_NORMAL
    
    
    PUSH AX
    MOV DL, '0'
    MOV AH, 2
    INT 21H
    POP AX
    
PRINT_NORMAL:
    
    CALL PRINT_NUM
    
    POP DX
    POP BX
    POP AX
    RET
PRINT_2DIGITS ENDP


DEFINE_SCAN_NUM
DEFINE_PRINT_STRING
DEFINE_PRINT_NUM
DEFINE_PRINT_NUM_UNS
DEFINE_PTHIS

END MAIN