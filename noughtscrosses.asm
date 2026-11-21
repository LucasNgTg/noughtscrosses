TITLE JOGO_VELHA
.MODEL SMALL
.STACK 100H

.DATA
  VIDEO_SEG EQU 0B800H
  ADDR_TAB EQU 710

  CLR_X EQU 0CH
  CLR_O EQU 09H
  CLR_LINES EQU 07H
  CLR_PLACEHOLDERS EQU 08H

  MATRIX DB 9 DUP(0)

  GAME_MODE DB 1
  TURN_NOW DB 'X'
  MOVE_COUNT DB 0
  WINNER DB 0

  ; Combinacoes vencedoras
  WIN_COMBOS DB 0,1,2, 3,4,5, 6,7,8
             DB 0,3,6, 1,4,7, 2,5,8
             DB 0,4,8, 2,4,6

  HSEP DB '--+---+--'
  LEN_HSEP EQU 9

  MSG_MENU DB '=== JOGO DA VELHA ===',13,10
           DB '1 - Jogador X Jogador',13,10
           DB '2 - Jogador X Computador',13,10
           DB 'Escolha 1 ou 2 (sem ENTER): $'

  MSG_MODE_ERROR DB 13,10
                 DB 'Modo invalido.',13,10,'$'

  MSG_TURN_X DB 13,10
             DB 'Jogador X - escolha (1-9): $'

  MSG_TURN_O DB 13,10
             DB 'Jogador O - escolha (1-9): $'

  MSG_INVALID DB 13,10
              DB 'Posicao invalida!',13,10,'$'

  MSG_BUSY DB 13,10
           DB 'Essa casa ja esta ocupada!',13,10,'$'

  MSG_X_WINS DB 13,10
             DB 'Vitoria do jogador X!',13,10,'$'

  MSG_O_WINS DB 13,10
             DB 'Vitoria do jogador O!',13,10,'$'

  MSG_CPU_WINS DB 13,10
               DB 'Vitoria do computador!',13,10,'$'

  MSG_DRAW DB 13,10
           DB 'Empate!',13,10,'$'

  MSG_REPLAY DB 13,10
             DB 'Jogar novamente? (S/N): $'

.CODE

; ==========================================
; PROGRAMA PRINCIPAL
; ==========================================

MAIN PROC

  MOV AX, @DATA
  MOV DS, AX

MENU:
  MOV AX, 0003H
  INT 10H

  LEA DX, MSG_MENU
  MOV AH, 09H
  INT 21H

  MOV AH, 00H
  INT 16H

  CMP AL, '1'
  JE SET_PVP

  CMP AL, '2'
  JE SET_PVC

  LEA DX, MSG_MODE_ERROR
  MOV AH, 09H
  INT 21H

  JMP MENU

SET_PVP:
  MOV GAME_MODE, 1
  JMP START_MATCH

SET_PVC:
  MOV GAME_MODE, 2

START_MATCH:
  CALL RESET_BOARD

GAME_LOOP:
  CALL DRAW_BOARD

  CMP GAME_MODE, 2
  JNE HUMAN_TURN

  CMP TURN_NOW, 'O'
  JNE HUMAN_TURN

  CALL CPU_MOVE
  JMP CHECK_MOVE

HUMAN_TURN:
  CALL HUMAN_MOVE

CHECK_MOVE:
  CALL CHECK_WIN

  CMP WINNER, 0
  JNE GAME_OVER

  CMP MOVE_COUNT, 9
  JE GAME_OVER

  CMP TURN_NOW, 'X'
  JE CHANGE_TO_O

  MOV TURN_NOW, 'X'
  JMP GAME_LOOP

CHANGE_TO_O:
  MOV TURN_NOW, 'O'
  JMP GAME_LOOP

GAME_OVER:
  CALL DRAW_BOARD

  CMP WINNER, 'X'
  JE SHOW_X_WIN

  CMP WINNER, 'O'
  JE SHOW_O_WIN

  LEA DX, MSG_DRAW
  JMP PRINT_RESULT

SHOW_X_WIN:
  LEA DX, MSG_X_WINS
  JMP PRINT_RESULT

SHOW_O_WIN:
  CMP GAME_MODE, 2
  JE SHOW_CPU_WIN

  LEA DX, MSG_O_WINS
  JMP PRINT_RESULT

SHOW_CPU_WIN:
  LEA DX, MSG_CPU_WINS

PRINT_RESULT:
  MOV AH, 09H
  INT 21H

  LEA DX, MSG_REPLAY
  MOV AH, 09H
  INT 21H

  MOV AH, 00H
  INT 16H

  ; CORRECAO DOS SALTOS DO TASM

  CMP AL, 'S'
  JE REINICIAR_JOGO

  CMP AL, 's'
  JE REINICIAR_JOGO

  JMP ENCERRAR_JOGO

REINICIAR_JOGO:
  JMP MENU

ENCERRAR_JOGO:
  MOV AX, 4C00H
  INT 21H

MAIN ENDP


; ==========================================
; REINICIALIZA O TABULEIRO
; ==========================================

RESET_BOARD PROC NEAR

  PUSH AX
  PUSH CX
  PUSH SI

  LEA SI, MATRIX
  MOV CX, 9

RESET_LOOP:
  MOV BYTE PTR [SI], 0
  INC SI

  LOOP RESET_LOOP

  MOV TURN_NOW, 'X'
  MOV MOVE_COUNT, 0
  MOV WINNER, 0

  POP SI
  POP CX
  POP AX

  RET

RESET_BOARD ENDP


; ==========================================
; JOGADA DO JOGADOR HUMANO
; ==========================================

HUMAN_MOVE PROC NEAR

  PUSH AX
  PUSH DX
  PUSH SI

ASK_MOVE:
  CMP TURN_NOW, 'X'
  JE ASK_X

  LEA DX, MSG_TURN_O
  JMP PRINT_PROMPT

ASK_X:
  LEA DX, MSG_TURN_X

PRINT_PROMPT:
  MOV AH, 09H
  INT 21H

  MOV AH, 00H
  INT 16H

  ; Testa entrada de 1 a 9

  CMP AL, '1'
  JB INVALID_MOVE

  CMP AL, '9'
  JA INVALID_MOVE

  ; Converte ASCII em indice de 0 a 8

  SUB AL, '1'
  XOR AH, AH
  MOV SI, AX

  ; Verifica se a casa esta livre

  CMP BYTE PTR MATRIX[SI], 0
  JNE OCCUPIED

  ; Grava X ou O

  MOV AL, TURN_NOW
  MOV MATRIX[SI], AL

  INC MOVE_COUNT

  JMP MOVE_OK

INVALID_MOVE:
  LEA DX, MSG_INVALID
  MOV AH, 09H
  INT 21H

  JMP ASK_MOVE

OCCUPIED:
  LEA DX, MSG_BUSY
  MOV AH, 09H
  INT 21H

  JMP ASK_MOVE

MOVE_OK:
  POP SI
  POP DX
  POP AX

  RET

HUMAN_MOVE ENDP


; ==========================================
; VERIFICA SE EXISTE VENCEDOR
; ==========================================

CHECK_WIN PROC NEAR

  PUSH AX
  PUSH BX
  PUSH CX
  PUSH SI
  PUSH DI

  LEA SI, WIN_COMBOS
  MOV CX, 8

CHECK_LINE:
  ; Primeira casa

  MOV BL, [SI]
  XOR BH, BH

  MOV DI, BX
  MOV AL, MATRIX[DI]

  CMP AL, 0
  JE NEXT_LINE

  ; Segunda casa

  MOV BL, [SI+1]
  XOR BH, BH

  MOV DI, BX

  CMP AL, MATRIX[DI]
  JNE NEXT_LINE

  ; Terceira casa

  MOV BL, [SI+2]
  XOR BH, BH

  MOV DI, BX

  CMP AL, MATRIX[DI]
  JNE NEXT_LINE

  ; Encontrou tres marcas iguais

  MOV WINNER, AL
  JMP END_CHECK

NEXT_LINE:
  ADD SI, 3
  LOOP CHECK_LINE

END_CHECK:
  POP DI
  POP SI
  POP CX
  POP BX
  POP AX

  RET

CHECK_WIN ENDP


; ==========================================
; BUSCA JOGADA TATICA DA CPU
; ==========================================

FIND_TACTIC PROC NEAR

  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI
  PUSH DI

  ; AL = marca que queremos analisar

  MOV DL, AL

  LEA SI, WIN_COMBOS
  MOV CX, 8

TACTIC_LINE:
  XOR DH, DH

  ; Indice da casa vazia
  MOV AH, 0FFH

  PUSH CX
  MOV CX, 3

TACTIC_CELL:
  MOV BL, [SI]
  XOR BH, BH

  MOV DI, BX
  MOV BL, MATRIX[DI]

  CMP BL, DL
  JE TACTIC_MATCH

  CMP BL, 0
  JE TACTIC_EMPTY

  ; Existe marca adversaria
  OR DH, 80H

  JMP TACTIC_ADVANCE

TACTIC_MATCH:
  INC DH
  JMP TACTIC_ADVANCE

TACTIC_EMPTY:
  MOV AH, [SI]

TACTIC_ADVANCE:
  INC SI

  LOOP TACTIC_CELL

  POP CX

  CMP DH, 2
  JNE TACTIC_NEXT

  CMP AH, 0FFH
  JE TACTIC_NEXT

  ; Retorna indice livre em AL
  MOV AL, AH

  JMP TACTIC_DONE

TACTIC_NEXT:
  LOOP TACTIC_LINE

  MOV AL, 0FFH

TACTIC_DONE:
  POP DI
  POP SI
  POP DX
  POP CX
  POP BX

  RET

FIND_TACTIC ENDP


; ==========================================
; JOGADA AUTOMATICA DO COMPUTADOR
; ==========================================

CPU_MOVE PROC NEAR

  PUSH AX
  PUSH SI

  ; Tenta completar uma linha de O

  MOV AL, 'O'
  CALL FIND_TACTIC

  CMP AL, 0FFH
  JNE CPU_PLACE

  ; Tenta impedir a vitoria de X

  MOV AL, 'X'
  CALL FIND_TACTIC

  CMP AL, 0FFH
  JNE CPU_PLACE

  ; Se possivel, ocupa o centro

  CMP BYTE PTR MATRIX[4], 0
  JNE CPU_FIND_FREE

  MOV AL, 4
  JMP CPU_PLACE

CPU_FIND_FREE:
  XOR SI, SI

CPU_SEARCH:
  CMP SI, 9
  JAE CPU_DONE

  CMP BYTE PTR MATRIX[SI], 0
  JE CPU_FOUND

  INC SI
  JMP CPU_SEARCH

CPU_FOUND:
  MOV AX, SI

CPU_PLACE:
  XOR AH, AH
  MOV SI, AX

  MOV BYTE PTR MATRIX[SI], 'O'

  INC MOVE_COUNT

CPU_DONE:
  POP SI
  POP AX

  RET

CPU_MOVE ENDP


; ==========================================
; DESENHO DO TABULEIRO
; ==========================================

DRAW_BOARD PROC NEAR

  PUSH AX
  PUSH DX
  PUSH CX
  PUSH SI
  PUSH DI
  PUSH ES

  CLD

  ; Limpa tela e seleciona modo texto

  MOV AX, 0003H
  INT 10H

  ; Segmento da memoria de video

  MOV AX, VIDEO_SEG
  MOV ES, AX

  LEA SI, MATRIX

  MOV DI, ADDR_TAB

  ; Contador ASCII das casas
  MOV AL, '1'

  ; Tres linhas
  MOV CX, 3

LIN:
  PUSH CX

  ; Tres colunas
  MOV CX, 3

  PUSH DI

COL:
  MOV AH, CLR_PLACEHOLDERS
  PUSH AX

  MOV AL, DS:[SI]

  CMP AL, 0
  JE PRINT_POS

  CMP AL, 'X'
  JE PRINT_X

  ; Impressao do O

  MOV AH, CLR_O
  MOV ES:[DI], AX

  POP AX

  JMP CONTINUE_PRINT_TAB

PRINT_X:
  MOV AH, CLR_X
  MOV ES:[DI], AX

  POP AX

  JMP CONTINUE_PRINT_TAB

PRINT_POS:
  POP AX
  MOV ES:[DI], AX

CONTINUE_PRINT_TAB:
  CMP CX, 1
  JE SKIP_PRINT_VSEP

PRINT_VSEP:
  ADD DI, 4

  PUSH AX

  MOV AL, '|'
  MOV AH, CLR_LINES

  MOV ES:[DI], AX

  POP AX

  ADD DI, 4

SKIP_PRINT_VSEP:
  INC AL
  INC SI

  LOOP COL

  ; Proxima linha

  POP DI
  ADD DI, 160

  CMP AL, '9'
  JA SKIP_PRINT_HSEP

  PUSH DI
  PUSH AX
  PUSH SI

  MOV AH, CLR_LINES

  LEA SI, HSEP
  MOV CX, LEN_HSEP

PRINT_HSEP:
  LODSB

  MOV ES:[DI], AX

  ADD DI, 2
  LOOP PRINT_HSEP

  POP SI
  POP AX
  POP DI

  ADD DI, 160

SKIP_PRINT_HSEP:
  POP CX

  LOOP LIN

  ; Posiciona cursor abaixo do tabuleiro

  MOV AH, 02H
  MOV BH, 00H
  MOV DX, 0A00H

  INT 10H

  POP ES
  POP DI
  POP SI
  POP CX
  POP DX
  POP AX

  RET

DRAW_BOARD ENDP

END MAIN
