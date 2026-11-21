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

  MATRIX DB 9 DUP(0)

  ; Vetor de teste
  ; Deve produzir X na diagonal principal
  ; MATRIX DB "X", 0, "O", 0, "X", 0, 0, 0, "X"

  MSG_NXT_MOVE DB "Digite a posicao do seu lance: $"

  HSEP  DB "--+---+--"
  LEN_HSEP EQU 9
.CODE
;description
MAIN PROC
  MOV AX, @DATA
  MOV DS, AX
  MOV ES, AX

  LEA BX, MATRIX

  ; jogo inicia com X
  MOV CL, "X"
  CALL DRAW_BOARD

L1:
  ; Pede ao usuário digitar o próximo lance
  MOV AH, 9
  LEA DX, MSG_NXT_MOVE
  INT 21h

  ; Lê o lance do jogador
  MOV AH, 1
  INT 21h

  ; Transformação do char em idx
  MOV SI, AX
  AND SI, 000Fh
  DEC SI

  ; atualiza matriz
  MOV [BX+SI], CL
  CALL DRAW_BOARD

  ; verifica se alguém venceu
  CALL WIN

  ; alterna o símbolo
  ; X = 01011000
  ; O = 01001111
  XOR CL, 17h
  CMP AL, 0
  JE L1

  ; espera o usuário apertar uma tecla
  ; antes de retornar o controle para o programa
  MOV AH, 0
  INT 16h
  
  MOV AH, 4Ch
  INT 21h
MAIN ENDP

; verifica quem venceu
; recebe:
;   SI = idx do último lance
;   BX = addr do primeiro elemento da matriz
; retorna:
;   AL = 0 -> jogo continua
;   AL = 1 -> empate
;   AL = "X" -> X vence
;   AL = "O" -> O vence
WIN PROC
  ; salva o valor atual dos regs
  PUSH CX
  PUSH DX
  PUSH DI

  ; AL = idx / 3
  ; AH = idx % 3
  MOV AX, SI
  MOV DL, 3
  DIV DL

  ; primeiro idx da linha
  ; DI = 3 * floor(idx / 3)
  MOV DI, AX
  ADD AL, AL
  ADD DI, AX
  AND DI, 00FFh

  ; DH tem o valor do primeiro idx da linha
  MOV DH, [BX+DI]

  ; se todos os valores da linha forem iguais,
  ; o jogador com o símbolo em DH vence
  CMP DH, [BX+DI+1]
  JNE NOT_ROW
  CMP DH, [BX+DI+2]
  JNE NOT_ROW
  JMP WINNER

NOT_ROW:
  ; primeiro idx da coluna
  ; DL = idx % 3
  MOV DI, AX
  SHL DI, 8

  ; DH tem o valor do primeiro idx da coluna
  MOV DH, [BX+DI]

  ; se todos os valores da coluna forem iguais,
  ; o jogador com o símbolo em [BX+SI] vence
  CMP DH, [BX+DI+3]
  JNE NOT_COL
  CMP DH, [BX+DI+6]
  JNE NOT_COL
  JMP WINNER

NOT_COL:
  ; DH tem o valor no meio do tabuleiro
  XOR AX, AX
  MOV DH, [BX+4]
  CMP DH, 0
  JE END_WIN

  ; se o idx não for par,
  ; o lance não foi em nenhuma das diagonais
  TEST SI, 1h
  JNZ CHECK_DRAW
  ; compara o valor do meio com os
  ; outros valores da diagonal secundária
  ; se forem iguais,
  ; o jogador com o símbolo em [BX+SI] vence
  ; caso contrário, checar diagonal principal
  CMP DH, [BX+2]
  JNE NOT_DIAG2
  CMP DH, [BX+6]
  JNE NOT_DIAG2
  JMP WINNER

NOT_DIAG2:
  ; se idx não for divisível por 4,
  ; o lance não foi na diagonal principal
  TEST SI, 3h
  JNZ CHECK_DRAW
  ; compara o valor do meio com os
  ; outros valores da diagonal principal
  ; se forem iguais,
  ; o jogador com o símbolo em [BX+SI] vence
  ; caso contrário, ver se o jogo empatou
  CMP DH, [BX]
  JNE CHECK_DRAW
  CMP DH, [BX+8]
  JNE CHECK_DRAW
  JMP WINNER

WINNER:
  MOV AL, [BX+SI]
  JMP END_WIN

CHECK_DRAW:
  ; verifica se há zeros na matriz
  ; se houver, o jogo continua
  MOV DI, BX
  MOV CX, 9
  REPNE SCASB
  JZ END_WIN
  INC AL

END_WIN:
  POP DI
  POP DX
  POP CX
  RET
WIN ENDP

; Desenha o tabuleiro na tela com o estado atual
DRAW_BOARD PROC
  ; Salva o valor atual dos regs
  PUSH ES
  PUSH AX
  PUSH DX
  PUSH CX
  PUSH SI
  PUSH DI

  MOV AX, ADDR
  MOV ES, AX

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

  ; Devolve os valores iniciais dos regs
  POP DI
  POP SI
  POP CX
  POP DX
  POP AX
  POP ES
  RET
DRAW_BOARD ENDP
END MAIN