TITLE JOGO_VELHA
.MODEL SMALL
.STACK 100h
.DATA
  ADDR EQU 0B800h
  START_TAB EQU 35 ; 39 - (9 / 2)
  ADDR_TAB EQU 710 ; 2 * (80 * 4 + 35)

  LF EQU 0Ah
  CR EQU 0Dh
  TAB EQU 09h
  NXT_LINE DB LF, CR, "$"

  CLR_X EQU 0Ch
  CLR_O EQU 09h
  CLR_LINES EQU 07h
  CLR_PLACEHOLDERS EQU 08h

  ; MATRIX DB 9 DUP(0)

  ; Vetor de teste
  ; Deve produzir X na diagonal principal
  MATRIX DB "X", 0, "O", 0, "X", 0, 0, 0, "X"

  MSG_NXT_MOVE DB "Digite a posicao do seu lance: $"

  HSEP  DB "--+---+--"
  LEN_HSEP EQU 9
.CODE
;description
MAIN PROC
  MOV AX, @DATA
  MOV DS, AX

  MOV AX, ADDR
  MOV ES, AX

  CALL DRAW_BOARD

  MOV AH, 1
  INT 21h

  MOV AH, 0
  INT 16h
  
  MOV AH, 4Ch
  INT 21h
MAIN ENDP

; Desenha o tabuleiro na tela com o estado atual
DRAW_BOARD PROC
  ; Salva o valor atual dos regs
  PUSH AX
  PUSH DX
  PUSH CX
  PUSH SI
  PUSH DI

  CLD

  LEA SI, MATRIX

  ; Modo vídeo-texto
  MOV AX, 3
  INT 10h
  ; Início do tabuleiro
  MOV DI, ADDR_TAB

  ; Contador ASCII
  MOV AL, "1"
  ; Contador de linhas
  MOV CX, 3
LIN:
  ; Salva o contador de linhas
  PUSH CX
  ; Reinicia o contador de colunas
  MOV CX, 3
  ; Guarda a posição atual do tabuleiro
  PUSH DI
COL:
  MOV AH, CLR_PLACEHOLDERS
  ; Salva a posição atual do contador ASCII
  PUSH AX
  ; Verifica o que está na posição atual da matriz
  MOV AL, DS:[SI]
  CMP AL, 0 ; Se for 0, a posição está livre
  JE PRINT_POS

  CMP AL, "X"
  JE PRINT_X

  ; Impressão do O
  MOV AH, CLR_O
  MOV ES:[DI], AX
  POP AX
  JMP CONTINUE_PRINT_TAB
PRINT_X:
  ; Impressão do X
  MOV AH, CLR_X
  MOV ES:[DI], AX
  POP AX
  JMP CONTINUE_PRINT_TAB
PRINT_POS:
  ; Retorna o contador ASCII
  POP AX
  MOV ES:[DI], AX
CONTINUE_PRINT_TAB:
  ; Se a última posição da linha foi impressa,
  ; pular o separador vertical
  CMP CX, 1
  JE SKIP_PRINT_VSEP
PRINT_VSEP:
  ADD DI, 4 ; Espaçamento

  PUSH AX
  MOV AL, "|"
  MOV AH, CLR_LINES
  MOV ES:[DI], AX
  POP AX

  ADD DI, 4 ; Espaçamento
SKIP_PRINT_VSEP:
  INC AL
  INC SI
  LOOP COL

  ; Passa para a próxima linha
  POP DI
  ADD DI, 160
  ; Se ultrapassou 9 (fim do tabuleiro),
  ; pula o separador horizontal
  CMP AL, "9"
  JA SKIP_PRINT_HSEP

  PUSH DI ; Salva a posição do tabuleiro
  PUSH AX ; Salva o contador ASCII
  PUSH SI ; Salva a posição na matriz

  MOV AH, CLR_LINES
  LEA SI, HSEP ; Carrega o separador horizontal
  MOV CX, LEN_HSEP
PRINT_HSEP:
  LODSB
  MOV ES:[DI], AX
  ADD DI, 2
  LOOP PRINT_HSEP

  POP SI
  POP AX
  POP DI
  ADD DI, 160 ; Passa para a próxima linha
SKIP_PRINT_HSEP:
  POP CX
  LOOP LIN

  ; Move o cursor para uma linha vazia
  ; com espaçamento de uma linha
  MOV AH, 2
  MOV DX, 0A00h
  INT 10h

  ; Pede ao usuário digitar o próximo lance
  MOV AH, 9
  LEA DX, MSG_NXT_MOVE
  INT 21h

  ; Devolve os valores iniciais dos regs
  POP DI
  POP SI
  POP CX
  POP DX
  POP AX
  RET
DRAW_BOARD ENDP
END MAIN