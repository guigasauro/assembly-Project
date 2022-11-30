; Guilherme Nogueira da Silva - 20200004428
.686
.model flat, stdcall
option casemap:NONE

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

.data
    ; output para requisitar o nome da imagem de entrada ao usuario
    outputNomeImagemEntrada db "Digite o nome do arquivo a ser aberto: ", 0ah, 0h

    ; output para requisitar o nome da imagem de saída ao usuario
    outputNomeImagemSaida db "Digite o nome do arquivo a ser criado: ", 0ah, 0h

    inputNomeImagemEntrada db 50 dup(0) ; variavel para armazenar o nome da imagem que sera tratada pelo programa
    inputNomeImagemSaida db 50 dup(0) ; variavel para armazenar o nome da imagem resultante do tratamento do programa

    ; prompt para que o usuario selecione a cor
    outputCodigoCor db "Insira a cor a ser aumentada (0 - azul, 1 - verde, 2 - vermelho): ", 0ah, 0h

    inputCodigoCor db 5 dup(0) ; input do usuario pro codigo de cor
    codigoCor dd 0 ; variavel para armazenar o codigo da cor que sera aumentada em cada pixel (0 - azul, 1 - verde, 2 - vermelho)

    stringAzul db "Insira o valor a ser incrementado para a cor azul (0 - 255): ", 0ah, 0h ; prompt caso o usuario escolha AZUL
    stringVerde db "Insira o valor a ser incrementado para a cor verde (0 - 255): ", 0ah, 0h ; prompt caso o usuario escolha VERDE
    stringVermelho db "Insira o valor a ser incrementado para a cor vermelho (0 - 255): ", 0ah, 0h ; prompt caso o usuario escolha VERMELHO

    inputValorIncremento db 5 dup(0) ; input do usuario pro valor de incremento
    valorIncremento dd 0 ; variavel para armazenar o numero em que vai ser acrescentado a cor

    inputHandle dd 0 ; variavel para armazenar o handle de entrada pro buffer do console
    outputHandle dd 0 ; variavel para armazenar o handle de saida pro buffer do console
    console_count dd 0 ; variavel para armazenar caracteres lidos/escritos no console
    tamanho_string dd 0 ; variavel para armazenar o tamanho da string

    fileHandleRead dd 0 ; variavel para armazenar o handle do arquivo que tera seus bytes lidos
    fileHandleWrite dd 0 ; variavel para armazenar o handle do arquivo onde serao escritos os bytes modificados
    cabecalhoBuffer db 54 dup(0) ; buffer para armazenar o cabecalho da imagem
    coresBuffer db 3 dup(0) ; buffer para armazenar cada pixel
    rwCount dd ? ; variavel para armazenar um contador de bytes essencialmente lidos no arquivo

.code
    ; caso o valor que usuario inseriu, quando somado com o byte que sera modificado, exceda 255,
    ; o valor do byte passa a ser 255
    tratamento_valorIncremento:
        mov ebx, 255
        
        jmp continue_muda_cor

    ; funcao responsavel pelo papel principal do programa, mudar a cor da imagem recebida
    muda_cor:
        ; em sua primeira execucao, o programa acaba de ler os bytes de cabecalho e escreve-los
        ; na imagem de saida, entao os 3 bytes lidos nessa linha de instrucao corresponderao
        ; ao 1o pixel da imagem

        ; lendo 1 pixel do arquivo
        invoke ReadFile, fileHandleRead, addr coresBuffer, 3, addr rwCount, NULL

        ; verificando se chegou ao fim do arquivo, e fechando o programa nesse caso
        cmp rwCount, 0
        je labelEnd

        ; incrementando a cor ao byte escolhido
        mov eax, codigoCor
        mov bl, coresBuffer[eax]
        mov eax, valorIncremento
        add ebx, eax
        cmp ebx, 255
        jae tratamento_valorIncremento

        ; label para continuar apos o tratamento do valor de incremento
        continue_muda_cor:

        ; guardando o byte modificado de volta no array de bytes
        mov eax, codigoCor
        mov coresBuffer[eax], bl

        ; escrevendo esse array na imagem de saida
        invoke WriteFile, fileHandleWrite, addr coresBuffer, 3, addr rwCount, NULL

        ; voltando pro começo da funcar
        jmp muda_cor

    start:
        ; definindo os handles de entrada e saida
        invoke GetStdHandle, STD_INPUT_HANDLE
        mov inputHandle, eax
        invoke GetStdHandle, STD_OUTPUT_HANDLE
        mov outputHandle, eax

        ; descobrindo o tamanho da string e guardando na variavel tamanho_string
        invoke StrLen, addr outputNomeImagemEntrada
        mov tamanho_string, eax

        ; printando "Digite o nome do arquivo a ser aberto: " e lendo o nome do arquivo no console
        invoke WriteConsole, outputHandle, addr outputNomeImagemEntrada, tamanho_string, addr console_count, NULL
        invoke ReadConsole, inputHandle, addr inputNomeImagemEntrada, sizeof inputNomeImagemEntrada, addr console_count, NULL

        ; descobrindo o tamanho da string e guardando na variavel tamanho_string
        invoke StrLen, addr inputNomeImagemEntrada
        mov tamanho_string, eax

        ; tratamento para retirada de caracteres CR e/ou LF, necessarios para uso de strings recebidas pelo usuário
        ; em funções como CreateFile, ReadFile e etc.
        mov esi, offset inputNomeImagemEntrada ; Armazenar apontador da string em esi

        proximo:
            mov al, [esi] ; Mover caractere atual para al
            inc esi ; Apontar para o proximo caractere
            cmp al, 13 ; Verificar se eh o caractere ASCII CR - FINALIZAR
            jne proximo
            dec esi ; Apontar para caractere anterior
            xor al, al ; ASCII 0
            mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CRs


        ; descobrindo o tamanho da string e guardando na variavel tamanho_string
        invoke StrLen, addr outputCodigoCor
        mov tamanho_string, eax
        
        ; printando "Insira a cor a ser aumentada (0 - azul, 1 - verde, 2 - vermelho): " e lendo o valor no console
        invoke WriteConsole, outputHandle, addr outputCodigoCor, tamanho_string, addr console_count, NULL
        invoke ReadConsole, inputHandle, addr inputCodigoCor, sizeof inputCodigoCor, addr console_count, NULL

        ; tratamento da string recebida pra uso da funcao 'atodw', verificando se existem bytes que nao sao numericos

        mov esi, offset inputCodigoCor ; Armazenar apontador da string em esi

        proximo1:
            mov al, [esi] ; Mover caracter atual para al
            inc esi ; Apontar para o proximo caracter
            cmp al, 48 ; Verificar se menor que ASCII 48 - FINALIZAR
            jl terminar1
            cmp al, 58 ; Verificar se menor que ASCII 58 - CONTINUAR
            jl proximo1
            terminar1:
            dec esi ; Apontar para caracter anterior
            xor al, al ; 0 ou NULL
            mov [esi], al ; Inserir NULL logo apos o termino do numero

        ; convertendo a string do codigo de cor para numero
        invoke atodw, addr inputCodigoCor
        mov codigoCor, eax

        ; vendo qual cor o usuario escolheu
        cmp codigoCor, 1
        jb corAzul
        je corVerde
        jg corVermelho

        corAzul:
            ; descobrindo o tamanho da string e guardando na variavel tamanho_string
            invoke StrLen, addr stringAzul
            mov tamanho_string, eax

            ; recebendo o valor de incremento do usuario para a cor azul
            invoke WriteConsole, outputHandle, addr stringAzul, tamanho_string, addr console_count, NULL
            invoke ReadConsole, inputHandle, addr inputValorIncremento, sizeof inputValorIncremento, addr console_count, NULL

            jmp continue

        corVerde:
            ; descobrindo o tamanho da string e guardando na variavel tamanho_string
            invoke StrLen, addr stringVerde
            mov tamanho_string, eax

            ; recebendo o valor de incremento do usuario para a cor verde
            invoke WriteConsole, outputHandle, addr stringVerde, tamanho_string, addr console_count, NULL
            invoke ReadConsole, inputHandle, addr inputValorIncremento, sizeof inputValorIncremento, addr console_count, NULL

            jmp continue

        corVermelho:
            ; descobrindo o tamanho da string e guardando na variavel tamanho_string
            invoke StrLen, addr stringVermelho
            mov tamanho_string, eax

            ; recebendo o valor de incremento do usuario para a cor vermelha
            invoke WriteConsole, outputHandle, addr stringVermelho, tamanho_string, addr console_count, NULL
            invoke ReadConsole, inputHandle, addr inputValorIncremento, sizeof inputValorIncremento, addr console_count, NULL

            jmp continue

        continue:

        ; tratamento da string recebida pra uso da funcao 'atodw', verificando se existem bytes que nao sao numericos
        
        mov esi, offset inputValorIncremento ; Armazenar apontador da string em esi

        proximo2:
            mov al, [esi] ; Mover caracter atual para al
            inc esi ; Apontar para o proximo caracter
            cmp al, 48 ; Verificar se menor que ASCII 48 - FINALIZAR
            jl terminar2
            cmp al, 58 ; Verificar se menor que ASCII 58 - CONTINUAR
            jl proximo2
            terminar2:
            dec esi ; Apontar para caracter anterior
            xor al, al ; 0 ou NULL
            mov [esi], al ; Inserir NULL logo apos o termino do numero

        ; convertendo a string de valor de incremento para numero
        invoke atodw, addr inputValorIncremento
        mov valorIncremento, eax

        ; abrindo o arquivo original
        invoke CreateFile, addr inputNomeImagemEntrada, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        mov fileHandleRead, eax

        ; lendo os bytes de cabecalho do arquivo original
        invoke ReadFile, fileHandleRead, addr cabecalhoBuffer, 54, addr rwCount, NULL
        
        ; descobrindo o tamanho da string e guardando na variável tamanho_string
        invoke StrLen, addr outputNomeImagemSaida
        mov tamanho_string, eax

        ; printando "Digite o nome do arquivo a ser criado: " e lendo o nome do arquivo no console
        invoke WriteConsole, outputHandle, addr outputNomeImagemSaida, tamanho_string, addr console_count, NULL
        invoke ReadConsole, inputHandle, addr inputNomeImagemSaida, sizeof inputNomeImagemSaida, addr console_count, NULL

        ; tratamento para retirada de caracteres CR e/ou LF, necessarios para uso de strings recebidas pelo usuário
        ; em funções como CreateFile, ReadFile e etc.
        mov esi, offset inputNomeImagemSaida ; Armazenar apontador da string em esi

        proximo3:
            mov al, [esi] ; Mover caractere atual para al
            inc esi ; Apontar para o proximo caractere
            cmp al, 13 ; Verificar se eh o caractere ASCII CR - FINALIZAR
            jne proximo3
            dec esi ; Apontar para caractere anterior
            xor al, al ; ASCII 0
            mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CRs

        ; criando o arquivo de saída
        invoke CreateFile, addr inputNomeImagemSaida, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
        mov fileHandleWrite, eax

        ; escrevendo os bytes de cabecalho lidos anteriormente no arquivo de saida
        invoke WriteFile, fileHandleWrite, addr cabecalhoBuffer, 54, addr rwCount, NULL

        ; pulando pra funcao
        jmp muda_cor

        ; quando a funcao termina, volta pra ca
        labelEnd:
            ; fechamento dos arquivos e saida do programa
            invoke CloseHandle, fileHandleRead
            invoke CloseHandle, fileHandleWrite

            invoke ExitProcess, 0

    end start