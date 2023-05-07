        ORG 100H  

 
;1-SUBBYTES:
;
;
; 
MACRO SUBBYTES ARR
    XOR SI,SI
    XOR DI,DI
    XOR AX,AX
    XOR BX,BX
    XOR CX,CX
    XOR DX,DX 
    
    
    MOV CX,10H
    
    LOOP1:
        MOV BL,ARR[SI]      ;getting the SI's value of the matrix SI works here as index  BL->current main matrix value       
        MOV AL,SBOX[BX]     ;getting the value of the BX's index to AL,SBOX is arranged in a way trivial to trace
        MOV ARR[SI],AL      ;substituting the vaue in the SI's index in MATRIX by DL
        
        DEC CX
        INC SI
        CMP CX,0H 
    JNZ LOOP1 
ENDM         


;2-SHIFTROWS:    
;first row :doesn't change at all
;second row : the leftmost element will be moved to the rightmost place with shifting the last elements to the left 
;third row : the leftmost 2 element will be moved to the rightmost places with shifting the last elements to the left
;fourth row : the leftmost 3 element will be moved to the rightmost places with shifting the last elements to the left    
MACRO SHIFTROWS ARR,
    
    XOR SI,SI           
    XOR DI,DI
    XOR AX,AX
    XOR BX,BX
    XOR CX,CX
    XOR DX,DX  
    
        
    MOV CL,10H         
    
    ;the idea is that the shift matrix is already aligned with the correct 
    ;arrangment for the desired output so all that is done in the code is using
    ;the values in the shift matrix as indeces for the desired output matrix! 
      
    LOOPMAIN: 
        MOV AL,ARR[SI]              ;putting in AL the SI's value in the main matrix
        MOV BL,MATRIXSHR[SI]        ;putting in BL the SI's value in the shift matrix  
        MOV MATRIXTEMP[BX],AL       ;putting in BX's index in the temporary matrix the value in AL 
        
                                        
        INC SI                       
        DEC CL                      
        CMP CL,0H
    JNZ LOOPMAIN 
    
    CALL RESTORESHRESULT 

ENDM



;3-MIXCOULUMNS:
;
;
;   
MACRO MIXCOLUMNS ARR,MATRIXMIX
    
    ;MOV CX,16
    XOR AX,AX
    XOR BX,BX
    XOR DX,DX
    XOR SI,SI
                ;DI FOR ROWS IN MATRIX, INPUT -- CH COLUMN COUNT/SIZE
                ;SI FOR COLUMNS                         DH NOT CHANGING COPIED IN -> CH,DL
                ;AL ARR OPERAND AND BL MATRIX OPERAND
                ;DI MOVES BY 1 ALONG MATRIX
                ;SI MOVES DOWNWARDS ALONG ARR
    MOV CL,04H
    MOV CH,04H
    MOV DH,CH           ;COPY COLUMN COUNT INTO DH
    
    LOOP1:
          XOR DI,DI
          MOV DL,DH     ;COPY COLUMN COUNT INTO DL
    LOOP2:
          MOV BL,00H    ;BL WHERE SHIT HAPPENS, MIGHT NOT BE RIGHT
          MOV CH,DH     ;RESET COLUMN COUNT
    LOOP3: 
          MOV AL,ARR[SI]                   
          MOV BL,MATRIX[DI]
                                           
          CMP BL,02H 
          
    JZ CALLMUL2 
    JNZ COMPAREBL3
         
         CALLMUL2: CALL MUL2
        
    JMP CONTINUATION
          

    COMPAREBL3:
        CMP BL,03H  
        JZ CALLMUL3
        JNZ CONTINUATION
        CALLMUL3: CALL MUL3 
         
    CONTINUATION:
                
        CMP CH,04H     ;BECAUSE I WONT XOR THE FIRST TIME ONLY
        JNZ XORING             
        MOV TEMP,AL    ;BUT I WILL MOVE IT TO TEMP
        JMP CONTINUATION2      ;I WILL JUMP BECAUSE I ALREADY MOVED SO NO NEED TO XOR
        XORING: XOR TEMP,AL
          
    CONTINUATION2:
        
        INC DI          ;MOVE TO SECOND ELEMENT IN ROW - MATRIX
        ADD SI,04H      ;MOVE ALONG COLUMN 
        CMP CH,01H       ;I WILL PUT IN MEMORY ON THE LAST ITERATION WHEN I'VE XOR'D 4 ELEMENTS
        JZ PUTINMEM 
        JNZ CONTINUE3
    
                                        
    PUTINMEM:  
        PUSH AX
        CALL IMIXCOLCPROC
        MOV AL, TEMP
        MOV RESMIX[BX],AL
        POP AX
          
    CONTINUE3:
        DEC CH ;MEANS WE'RE DONE WITH 1/4 OF THE WORK FOR ONE ELEMENT IN THIS LOOP
        
        JNZ LOOP3  
        SUB DI,04H     ;RESET ROW COUNT                            
        SUB SI,10H     ;RESET COL COUNT 
        ADD DI,04H     ;MOVE TO THE SECOND ROW BUT STAY SAME COL
                     ; - SINCE WE ISOLATE COL BY COL FROM ARR     
        DEC DL         ;DECREMENTING COL COUNTS, WORK ON NEXT 2,3,4 ELEMENTS OF THE SAME COL BY                                   
        JNZ LOOP2      ;MOVING TO THE 2ND,3RD AND 4TH ROWS RESPECTIVELY                                                    
        INC SI         ; MOVE TO 2ND,3RD AND 4TH COL 
        MOV DI,00H     ;RESET ROW COUNTER EVERYTIME
        DEC CL         ;DEC THE NUMBER OF REMAINING COL
        JNZ LOOP1
        CALL RESTOREARR
      
      
ENDM     

  
;4-ADDROUNDKEY:
;The macro function present here is responsible for ADDING the round key to the main matrix
;By adding the round key it is meant that we are the XORing the main matrix that is been cipherd with the 
;A new RoundKey(0~10) that is generated every round during the encryption process         
ADDROUNDKEY MACRO ARR, ROUNDKEYMATRIX  

    LOCAL LOOP1 
    XOR SI,SI
    XOR DI,DI
    XOR AX,AX
    XOR BX,BX
    XOR CX,CX
    XOR DX,DX

    LEA SI, ARR                  ;Pointer for MainMatrix elements
    LEA DI, roundKeyMatrix       ;Pointer for RoundKeyMatrix
    MOV CL, 10H                  ;Counter for 16 elements in a the matrix
    
    LOOP1:                       ;The body of the loop
        MOV BL ,[DI]             ;temporarily store the current element of RoundKey matrix in BL register
        MOV BH ,[SI]             ;temporarily store the current element of MainMatrix matrix in BL register
        XOR BH ,BL               ;Xoring the two current element of (Main,RoundKey) matrix to fullfill the logic of the AddRoundKey and store the value in BH 
        MOV [SI],BH              ;OverWrite the original value of MainMatrix by result value of XORing
        INC SI                   ;index Pointer to traverse the elements of the MainMatrix
        INC DI                   ;index Pointet to traverse the elements of the RoundKeyMatrix
        DEC CL                   ;counter to get the number of elements remaining
    JNZ LOOP1                    ;If the CL !=0 (means still elements remainig in the matrix)
 
ENDM  


.DATA     SEGMENT
  
;The main matrix to be input from the user
;used around the entire code  
ARR        DB 16 DUP(0)  



;Empty matrix used temporarily to hold the values of the matrix during some operation
;<<used in 2-SHIFTROWS>> 
MATRIXTEMP  DB 16 DUP(0)         ;temporary matrix to be filled with the output matrix after the shift row

;the shift matrix which has the indeces of the desired
;output matrix substituted with original indeces of the main input matrix
;<<used in 2-SHIFTROWS>> 
MATRIXSHR   DB 00H,01H,02H,03H    
            DB 07H,04H,05H,06H
            DB 0AH,0BH,08H,09H
            DB 0DH,0EH,0FH,0CH

 
 
 
INDEXTRANSPOSE DB 00H,04H,08H,0CH,
               DB 01H,05H,09H,0DH,
               DB 02H,06H,0AH,0EH,
               DB 03H,07H,0BH,0FH

RESMIX  DB 16 DUP(?) 

TEMP    DB DUP(0) 

IMIXCOL DB DUP(0)
 
 
;*****************************PREDIFINED MATRICES********************************


;<<used in 1-SUBBYTES>>  
;SBOX matrix
 SBOX   DB 63H,7CH,77H,7BH,0F2H,6BH,6FH,0C5H,30H,01H,67H,2BH,0FEH,0D7H,0ABH,76H
        DB 0CAH,82H,0C9H,7DH,0FAH,59H,47H,0F0H,0ADH,0D4H,0A2H,0AFH,9CH,0A4H,72H,0C0H
        DB 0B7H,0FDH,93H,26H,36H,3FH,0F7H,0CCH,34H,0A5H,0E5H,0F1H,71H,0D8H,31H,15H
        DB 04H,0C7H,23H,0C3H,18H,96H,05H,9AH,07H,12H,80H,0E2H,0EBH,27H,0B2H,75H
        DB 09H,83H,2CH,1AH,1BH,6EH,5AH,0A0H,52H,3BH,0D6H,0B3H,29H,0E3H,2FH,84H
        DB 53H,0D1H,00H,0EDH,20H,0FCH,0B1H,5BH,6AH,0CBH,0BEH,39H,4AH,4CH,58H,0CFH
        DB 0D0H,0EFH,0AAH,0FBH,43H,4DH,33H,85H,45H,0F9H,02H,7FH,50H,3CH,9FH,0A8H
        DB 51H,0A3H,40H,8FH,92H,9DH,38H,0F5H,0BCH,0B6H,0DAH,21H,10H,0FFH,0F3H,0D2H
        DB 0CDH,0CH,13H,0ECH,5FH,97H,44H,17H,0C4H,0A7H,7EH,3DH,64H,5DH,19H,73H
        DB 60H,81H,4FH,0DCH,22H,2AH,90H,88H,46H,0EEH,0B8H,14H,0DEH,5EH,0BH,0DBH
        DB 0E0H,32H,3AH,0AH,49H,06H,24H,5CH,0C2H,0D3H,0ACH,62H,91H,95H,0E4H,79H
        DB 0E7H,0C8H,37H,6DH,8DH,0D5H,4EH,0A9H,6CH,56H,0F4H,0EAH,65H,7AH,0AEH,08H
        DB 0BAH,78H,25H,2EH,1CH,0A6H,0B4H,0C6H,0E8H,0DDH,74H,1FH,4BH,0BBH,8BH,8AH
        DB 70H,3EH,0B5H,66H,84H,03H,0F6H,0EH,61H,35H,57H,0B9H,86H,0C1H,1BH,9EH
        DB 0E1H,0F8H,98H,11H,69H,0D9H,8EH,94H,9BH,1EH,87H,0E9H,0CEH,55H,28H,0DFH
        DB 8CH,0A1H,89H,0DH,0BFH,0E6H,42H,68H,41H,99H,2DH,0FH,0B0H,54H,0BBH,16H
        
        
;<<used in 3-MIXCOLUMNS>> 
MATRIXMIX   DB 02H,03H,01H,01H,01H,02H,03H,01H,01H,01H,02H,03H,03H,01H,01H,02H  


;The Genterated 10 round keys with the original ket (RoundKey0)  
;<<used in 4-ADDROUNDKEY>>
RoundKey0  DB  2bH,  28H, 0ABH,  09H,  7EH, 0AEH, 0F7H, 0CFH,  15H, 0D2H,  15H,  4FH,  16H, 0A6H,  88H,  3CH
RoundKey1  DB 0A0H,  88H,  23H,  2AH, 0FAH,  54H, 0A3H,  6CH, 0FEH,  2CH,  39H,  76H,  17H, 0B1H,  39H,  05H
RoundKey2  DB 0F2H,  7AH,  59H,  73H, 0C2H,  96H,  35H,  59H,  95H, 0B9H,  80H, 0F6H, 0F2H,  43H,  7AH,  7FH 
RoundKey3  DB  3DH,  47H,  1eH,  6DH,  80H,  16H,  23H,  7AH,  47H, 0FEH,  7EH,  88H,  7DH,  3EH,  44H,  3BH
RoundKey4  DB 0EFH, 0A8H, 0B6H, 0DBH,  44H,  52H,  71H,  0BH, 0A5H,  5BH,  25H, 0ADH,  41H,  7FH,  3BH,  00H
RoundKey5  DB 0D4H,  7CH, 0CAH,  11H, 0D1H,  83H, 0F2H, 0F9H, 0C6H,  9DH, 0B8H,  15H, 0F8H,  87H, 0BCH, 0BCH
RoundKey6  DB  6DH,  11H, 0DBH, 0CAH,  88H,  0BH, 0F9H,  00H, 0A3H,  3EH,  86H,  93H,  7AH, 0FDH,  41H, 0FDH
RoundKey7  DB  4EH,  5FH,  84H,  4EH,  54H,  5FH, 0A6H, 0A6H, 0F7H, 0C9H,  4FH, 0DCH,  0EH, 0F3H, 0B2H,  4FH
RoundKey8  DB 0EAH, 0b5H,  31H,  7FH, 0D2H,  8DH,  2BH,  8DH,  73H, 0BAH, 0F5H,  29H,  21H, 0D2H,  60H,  2FH
RoundKey9  DB 0ACH,  19H,  28H,  57H,  77H, 0FAH, 0D1H,  5CH,  66H, 0DCH,  29H,  00H, 0F3H,  21H,  41H,  6EH
RoundKey10 DB 0D0H, 0C9H, 0E1H, 0B6H,  14H, 0EEH,  3FH,  63H, 0F9H,  25H,  0CH,  0CH, 0A8H,  89H, 0C8H, 0A6H





;;ARRINPUT DB 18,?,18 DUP(?)



.CODE  SEGMENT     
    
      READ PROC    
      MOV AH,0AH    
      MOV DX, OFFSET ARRINPUT
      INT 21H
     CALL  
        ret
      READ ENDP  
         
         
         
     RESTORESHRESULT PROC   ; a stable procedure for transfering values from one matrix to another
        MOV BX,10H
        LOOPX:MOV AL,MATRIXTEMP[BX]
        MOV ARR[BX],AL
        DEC BX
        CMP BX,00H
        JNZ LOOPX 
                           ;IMPORTANT:the temporary matrix is corrupted after transfering its values to the main matrix  

           RET 
        RESTORESHRESULT ENDP

    
      
     MUL2 PROC
        
        CMP AL,80H
        JAE LEFTMOST1
        SAL AL,1
        JMP FINH
        LEFTMOST1:
        SAL AL,1
        XOR AL,1BH
        FINH:RET 
        MUL2 ENDP
     
     
       
       MUL3 PROC 
       
        XOR AH,AH
        MOV AH,AL
        CALL MUL2
        XOR AL,AH
        MOV AH,0 
       
        RET
        MUL3 ENDP 
       
       IMIXCOLCPROC PROC
        XOR BH,BH 
        MOV BL,IMIXCOL
        MOV AL,INDEXTRANSPOSE[BX]
        MOV BL,AL
        
         INC IMIXCOL
                RET
        
        IMIXCOLCPROC ENDP

        RESTOREARR PROC
        MOV IMIXCOL,00H
        MOV BX,10H
        LOOPX:MOV AL,RESMIX[BX]
        MOV ARR[BX],AL
        DEC BX
        CMP BX,00H
        JNZ LOOPX   
            
           RET 
        RESTOREARR ENDP
     
     
     
     
   
   
   
     
     
   

.data

TempRoundKeyLoc DB DUP(0)  ;create empty location in the meomry intialized with zero 

matrix1 DB 04H,0E0H,48H,28H,66H,0CBH,0F8H,06H,81H,19H,0D3H,26H,0E5H,9AH,7AH,4CH 


RoundKey   DB  00H, 00H,  00H,   00H,  00H,  00H,  00H,  00H,  00H,  00H,  00H,  00H,  00H,  00H,  00H,  00H
RoundKey0  DB  2bH,  28H, 0ABH,  09H,  7EH, 0AEH, 0F7H, 0CFH,  15H, 0D2H,  15H,  4FH,  16H, 0A6H,  88H,  3CH
RoundKey1  DB 0A0H,  88H,  23H,  2AH, 0FAH,  54H, 0A3H,  6CH, 0FEH,  2CH,  39H,  76H,  17H, 0B1H,  39H,  05H
RoundKey2  DB 0F2H,  7AH,  59H,  73H, 0C2H,  96H,  35H,  59H,  95H, 0B9H,  80H, 0F6H, 0F2H,  43H,  7AH,  7FH 
RoundKey3  DB  3DH,  47H,  1eH,  6DH,  80H,  16H,  23H,  7AH,  47H, 0FEH,  7EH,  88H,  7DH,  3EH,  44H,  3BH
RoundKey4  DB 0EFH, 0A8H, 0B6H, 0DBH,  44H,  52H,  71H,  0BH, 0A5H,  5BH,  25H, 0ADH,  41H,  7FH,  3BH,  00H
RoundKey5  DB 0D4H,  7CH, 0CAH,  11H, 0D1H,  83H, 0F2H, 0F9H, 0C6H,  9DH, 0B8H,  15H, 0F8H,  87H, 0BCH, 0BCH
RoundKey6  DB  6DH,  11H, 0DBH, 0CAH,  88H,  0BH, 0F9H,  00H, 0A3H,  3EH,  86H,  93H,  7AH, 0FDH,  41H, 0FDH
RoundKey7  DB  4EH,  5FH,  84H,  4EH,  54H,  5FH, 0A6H, 0A6H, 0F7H, 0C9H,  4FH, 0DCH,  0EH, 0F3H, 0B2H,  4FH
RoundKey8  DB 0EAH, 0b5H,  31H,  7FH, 0D2H,  8DH,  2BH,  8DH,  73H, 0BAH, 0F5H,  29H,  21H, 0D2H,  60H,  2FH
RoundKey9  DB 0ACH,  19H,  28H,  57H,  77H, 0FAH, 0D1H,  5CH,  66H, 0DCH,  29H,  00H, 0F3H,  21H,  41H,  6EH
RoundKey10 DB 0D0H, 0C9H, 0E1H, 0B6H,  14H, 0EEH,  3FH,  63H, 0F9H,  25H,  0CH,  0CH, 0A8H,  89H, 0C8H, 0A6H


.code      
                   
  
ADDRoundKey matrix1 ,                    


RoundKeyIter PROC 

    XOR BH, BH 

    MOV SI , offset RoundKey0    ;The register is used to hold the offset of the Roundey matrix 
 
                  ;inside this body we will overwrite the elements of RoundKey with the RoundKey[i] 
    MOV CL ,10H
    MOV BL, TempRoundKeyLoc  ;The offset of the last matrix used  

    INNERLOOP:
        MOV DX , [BX]
        MOV [SI] , Dx
        INC SI
        INC BL
        DEC CL
        JNZ INNERLOOP

    MOV TempRoundKeyLoc , BL ;after exectution of the loop , the last value of the matrix index will be saved in the fixed location  

ret
RoundKeyIter ENDP


HLT





