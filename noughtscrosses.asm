TITLE JOGO_VELHA
.MODEL SMALL
.STACK 100h
.DATA
  LF EQU 0Ah
  CR EQU 0Dh
  TAB EQU 09h
  NXT_LINE DB LF, CR, "$"
  MATRIX DB 9 DUP(0)

  ; Vetor de teste
  ; Deve produzir X na diagonal principal
  ; MATRIX DB "X", 0, 0, 0, "X", 0, 0, 0, "X"

  VSEP  DB " | $"
  HSEP  DB TAB, "--+---+--", LF, CR, "$"
.CODE
;description
MAIN PROC
  MOV AX, @DATA
  MOV DS, AX

  CALL DRAW_BOARD
  
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

  ; Carrega a matriz em SI
  LEA SI, MATRIX
  ; Inicia o contador ASCII
  MOV DL, "1"
  ; Inicia o contador de linhas
  MOV CX, 3

; Loop da linha
L1:
  ; Salva o estado do contador de linhas
  PUSH CX
  ; Inicia o contador de colunas
  MOV CX, 3

  MOV AH, 2

  ; Salva o contador ASCII
  PUSH DX
  ; Imprime espaçamento
  MOV DL, TAB
  INT 21h
  ; Retoma o contador ASCII
  POP DX

; Loop da coluna
L2:
  ; Volta para a função de impressão de char
  MOV AH, 2

  ; Se o valor no idx da matriz for 0
  ; Imprime o número do contador
  ; Caso contrário, imprime o valor no idx da matriz
  MOV DH, [SI]
  CMP DH, 0
  JE PRINT_POS

  ; Salva o contador ASCII
  PUSH DX
  ; Imprime o valor no idx da matriz
  MOV DL, [SI]
  INT 21h
  ; Retoma o contador ASCII
  POP DX

  ; Pula a impressão do contador
  JMP SKIP_PRINT_POS
PRINT_POS:
  INT 21h
SKIP_PRINT_POS:
  ; Se estiver na última iteração de colunas,
  ; pula o separador de colunas
  CMP CX, 1
  JE SKIP_VSEP

  ; Salva o contador ASCII
  PUSH DX
  ; Imprime o separador de colunas
  MOV AH, 9
  LEA DX, VSEP
  INT 21h
  ; Retoma o contador ASCII
  POP DX
SKIP_VSEP:
  ; Incrementa o contador ASCII
  INC DL
  ; Incrementa o idx
  INC SI

  LOOP L2

  ; Retoma o contador de linhas
  POP CX
  ; Se estiver na última iteração de linhas,
  ; Pula o separador de linhas
  CMP CX, 1
  JE SKIP_HSEP

  ; Salva o contador ASCII
  PUSH DX
  ; Passa para a próxima linha
  MOV AH, 9
  LEA DX, NXT_LINE
  INT 21h
  ; Imprime o separador de linhas
  LEA DX, HSEP
  INT 21h
  ; Retoma o contador ASCII
  POP DX
SKIP_HSEP:
  LOOP L1

  ; Devolve os valores iniciais dos regs
  POP SI
  POP CX
  POP DX
  POP AX
  RET
DRAW_BOARD ENDP
END MAIN