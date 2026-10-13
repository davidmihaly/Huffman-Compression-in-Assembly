;Mihaly David Zsolt, mdim2555, 512
;Huffmann tomorito


;nasm -f win32 Project.asm
;nlink
;p "D:\UBB Informatika\1. Felev\Projects\aclab\Huffman tomorito program\test" c		- compress
;p "D:\UBB Informatika\1 Felev\Projects\aclab\Huffman tomorito program\test.huff" d			-decompress

%include 'mio.inc'
%include 'io.inc'
%include 'util.inc'


global main



section .text

;debug

DebugPrintNode:

    pusha

    mov ebx, eax            ; save index
    shl eax, 4              ; eax = index * 16 (node offset)

    ;print node index:
    
    mov eax, ebx
    call io_writeint
    call NewLine

    ;frequency
	mov eax, ebx
    shl eax, 4
    mov eax, [huffmannTree + eax]
    call io_writeint
    call NewLine

    ;character
    mov eax, ebx
    shl eax, 4
    mov eax, [huffmannTree + eax + 4]
    call io_writeint
    call NewLine

    ; left
    mov eax, ebx
    shl eax, 4
    mov eax, [huffmannTree + eax + 8]
    call io_writeint
    call NewLine

    ;right 
    mov eax, ebx
    shl eax, 4
    mov eax, [huffmannTree + eax + 12]
    call io_writeint
    call NewLine

    call NewLine

    popa
ret

DebugPrintAllNodes:

    pusha


	

    xor ecx, ecx                ; ecx = current node index

	.print_loop:

    cmp ecx, [nodeCount]
    jge .done

    mov eax, ecx
    call DebugPrintNode         ; prints one node

    inc ecx
    jmp .print_loop

 	.done:
    popa
ret

DebugPrintActiveNodes:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    xor edi, edi                    ; edi = active index

	.loop:
    cmp edi, [activeCount]
    jge .done

   

    mov eax, edi
    call io_writeint

	call NewLine

    mov eax, [active + edi*4]      ; eax = node index
    call io_writeint
    call NewLine

    ; ---- Use DebugPrintNode to print the node ----
    mov eax, [active + edi*4]      ; node index in eax
    call DebugPrintNode

    call NewLine

    inc edi
    jmp .loop

	.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
ret

;reads from esi to the buffer in edi
ReadFromFile:

	pusha

	

	mov eax,FilePath		;get file path
	mov ebx,0				;set open mode to read
	call fio_open
	push eax
	
	;int3
	mov ebx,extensionTest		;get extension
	mov ecx, 4					;set size to 4
	call fio_read				;write extension

	
	
	;check if the file is a HUFF file create by the program
	mov esi,extension
	mov edi,extensionTest
	call StrCmp

	cmp eax,1		;if the strings are equal write error and exit
	je .ok
	pop eax
	mov eax,err_Huff
	call io_writestr
	call fio_close		;close file
	jmp error_exit

	.ok:

	pop eax
	call fio_close
	mov eax,FilePath
	mov ebx,0				; read mode
	call fio_open	

	mov ebx,buffer			;get buffer 
	mov ecx,[bufferSize]	;get the file size
	call fio_read

	
	call fio_close
	mov [bytesToRead],edx	; set how many bytes were read

	

	


	popa
ret

;saves the filepath to the FilePath variable
GetFilePath:		

	pusha

	call getargs ;get the comman line string into eax

	xor ecx,ecx

	mov bl,[eax + ecx]		;get first charachter
	inc ecx		
	cmp bl,'"'			;check if the program adress is surrounded by "
	jne .skipProgramName

	.skipUntil:					;if the program name is written in " " skip it

		mov bl,[eax + ecx]		;get char
	
		cmp bl, 0				;check if the end of the string was reached
    	je .done 	

		inc ecx					;increase index
		cmp bl, '"'				;cmp charachter to " jump until it is found
		jne .skipUntil

	jmp .skipSpaces

	.skipProgramName:			;skip the proagram name if it's not written in ""


		mov bl,[eax + ecx]		;get charachter
	
		cmp bl, 0				;check if the end of the file was reached
    	je .done 	

		inc ecx
		cmp bl, ' '				;check if a whitespace charachter was reached
		jne .skipProgramName

	
	

	.skipSpaces:		;skips spaces

		mov bl, [eax + ecx]		;get charachter
    	cmp bl, ' '				;check for whitespace charachters
    	jne .startCopy
    	inc ecx					;increase index
    	jmp .skipSpaces
		

	.startCopy:			;copy file path

	xor edx,edx

	mov bl, [eax + ecx]			;get first char
	cmp bl,'"'					;compare char to ""
	jne .copy
	
	inc ecx						;if the first char is a "" skip over it

	.copy:

		mov bl, [eax + ecx]		;get charachter
		cmp bl,'"'				;check if the char is a '
		je .done

		mov [FilePath + edx], bl	;copy char to filepath
		inc ecx						;increse index
		inc edx						;increase filepath index
		jmp .copy

	.done:

	mov [FilePath + edx], byte 0	;move a 0 byte to the end of the string

	inc ecx		;increase index
	
	.skipSpaces2:		;skips spaces

		mov bl, [eax + ecx]		;get charachter
    	cmp bl, ' '				;check for whitespace charachters
    	jne .getAppMode
    	inc ecx					;increase index
    	jmp .skipSpaces2
		

	.getAppMode:

	
	mov bl,[eax + ecx]			;get app mode
	mov [appMode],bl			;save app mode

	popa

ret

;iterates through the buffer and sets the frequency of each charachter
SetFreq:

	pusha

	xor ecx, ecx
	.clearFreq:
    mov dword [freq + ecx*4], 0
    inc ecx
    cmp ecx, 256
    jne .clearFreq


	xor ecx,ecx

	.loopBuffer:

		;cmp ecx,[bytesToRead]				;check if the end of the file was reached
		cmp ecx,[bytesToRead]
		je .end

		movzx eax, byte [buffer + ecx]		;get charachter

		inc dword [freq + eax*4] 			;incease frequency of eax


		inc ecx
		jmp .loopBuffer
	.end:

	mov dword [freq + 256*4], 1		;set the freq for the ff charachter(EOF)
	popa
ret

WriteFreq:

	pusha

		mov ecx,60

		.loop:

			cmp ecx,150
			jg .end

			mov eax,ecx

			call mio_writechar

			call NewLine
			call NewLine

			mov eax,[freq + ecx * 4]
			call io_writeint
			
			call NewLine

			inc ecx
			jmp .loop
		.end:

	popa

ret

WriteCodes:

	pusha

		xor ecx,ecx

		.loop:

			cmp ecx,256
			je .end


			mov bl,[codeLenght + ecx]
			cmp bl,0
			je .next



			mov eax,ecx

			call mio_writechar

			call NewLine
			call NewLine

			mov eax,[codes + ecx * 4]
			call io_writebin
			
			call NewLine

			.next:

			inc ecx
			jmp .loop
		.end:

	popa
ret

;compares the strings stored in esi and edi return 0 if equal 1 if not equal
StrCmp:
	.loop:
    	mov   al, [esi]        ;load current byte of string 1
    	mov   dl, [edi]        ;load current byte of string 2
    	cmp   al, dl
    	jne   .different       ;if the bytes differ the string are different
    	test  al, al        ;is the string the null terminator
    	jz    .equal        ;if yes they are equal
   	    inc   esi
    	inc   edi
    	jmp   .loop

	.equal:
    	xor   eax, eax      ;return 0
    	ret

	.different:
    	mov eax,1 		;if they are different return 1
    	ret

;returns the length of the string given by esi
StrLen:
 
	push ebx
	push ecx
	push edx
	push edi
	push esi
	
	;clear registers
	xor eax,eax
	xor ebx,ebx
	xor ecx,ecx

	;count elements
	.next:
	
		mov bl,[esi + eax]
		
		cmp bl,0
		je .end
		
		inc eax	
	
	jmp .next

	.end:

	pop esi
	pop edi
	pop edx
	pop ecx
	pop ebx
ret

;writes a string from the adress in esi
WriteStr:
	
	pusha
	
	;clear ecx
	xor ecx,ecx
	
	
	
	.next:
		
		;get charachter from the string
		mov al, [esi+ecx]
		
		;check if the end of the charachter was reached
		cmp al,0
		je .end
		
		;write out charachter
		call mio_writechar
		
		;increase index
		inc ecx
		
		jmp .next
	
	.end:
	
	popa
	
		
	
ret

;writes out a new line
NewLine:

	call mio_writeln
ret

;concatenates the string given by edi and esi
StrCat:

	pusha

	;save esi
	push esi
	push edi
	
	;get the length of edi
	mov esi,edi
	call StrLen
	
	
	
	pop edi
	pop esi
	
	;ecx will serve as the index of the concatenated string
	mov ecx, eax
	
	
	;edx will be the index of the other string
	xor edx,edx

	.next:
	
		mov bl,[esi + edx]
		
		
		cmp bl,0
		je .end
		
		mov [edi + ecx], bl
		
		inc edx
		inc ecx
		
		jmp .next

	.end:
	
	mov [edi + ecx], byte 0
	
	popa
ret

;finds the two smallest active nodes and returns their indexes in eax and ebx
FindSmallestActiveNodes:
	pusha

		mov dword [smallest],0		;will hold the index of the smallest node
		mov dword [secmdSmallest],0	;will hold the index of the second smallest node

		mov ebx,0x7FFFFFFF	;ebx will hold the frequency of the smallest node
		mov edx,0x7FFFFFFF	;edx will hold the frequency of the second smallest node

		xor edi,edi 	;edi will be the index

		xor ebp,ebp		;has a value been fiind for the smallest

		.FindSmallestActive:

			cmp edi,[activeCount]	;check if the index is equal to the nr of active nodes
			jge .FindSmallestActiveEnd

			

			mov eax,[active + edi*4]		;get next active node index

			shl eax, 4					

			

			mov ecx,[huffmannTree + eax]		;get the node's frequency
			
			

			cmp ebp,0
			jne .compare					;if the node is the first

			mov ebx,ecx						;save frequency
			mov esi,[active + edi*4]		;get index
			mov [smallest],esi

			jmp .nextIteration

			.compare:

			cmp ecx,ebx					;check if the current nodes frequency is smaller than the  smallest node's
			jge .checkSecondSmallest

			mov esi,[smallest]			;get the value of the previous smallest
			mov [secmdSmallest],esi		;set secondsmallest
			mov esi,[active + edi*4]	;get the value of the current smallest from the active list
			mov [smallest],esi			;set smallest
			mov edx,ebx					;sed secondsmallest's frequency
			mov ebx,ecx					;set smallest's frequenccy

			jmp .nextIteration

			.checkSecondSmallest:
			cmp ecx,edx					;check if the current node's frequency is smaller than the second smallest node's frequency			
			jge .nextIteration

			mov esi,[active + edi*4]		
			mov [secmdSmallest],esi			;set secondsmallest
			mov edx,ecx

			.nextIteration:


			
			mov ebp,1
			inc edi
			jmp .FindSmallestActive

		.FindSmallestActiveEnd:

	popa
	mov eax, [smallest]
	mov ebx, [secmdSmallest]
	
ret

;finds the two smallest active nodes and returns their indexes in eax a
FindSmallestActiveNode:
	push ebx
	push ecx 
	push edx
	push edi
	push esi
	push ebp

		

		xor edi,edi 	;edi will be the index

		mov eax, [active]        ; first active node index
   		mov esi, eax             ; esi  is smallest index

    	shl eax, 4
    	mov ebx, [huffmannTree + eax]   ; ebx = smallest freq

    	inc edi

		.FindSmallestActive:

			cmp edi,[activeCount]	;check if the index is equal to the nr of active nodes
			jge .FindSmallestActiveEnd

			mov eax,[active + edi*4]		;get next active node index

			shl eax, 4					
			mov ecx,[huffmannTree + eax]		;get the node's frequency
			
			cmp ecx,ebx					;check if the current nodes frequency is smaller than the  smallest node's
			jge .nextIteration

			
			mov esi,[active + edi*4]	;get the value of the current smallest from the active list
			mov ebx,ecx					;set smallest's frequenccy

			jmp .nextIteration

			

			.nextIteration:


			
			
			inc edi
			jmp .FindSmallestActive

		.FindSmallestActiveEnd:

		mov eax,esi

	pop ebp
	pop esi
	pop edi
	pop edx
	pop ecx
	pop ebx
	
	
ret

;Removes the nodes with the index given by eax
RemoveFromActive:

	pusha

	
	mov ecx,[activeCount]		;number of active nodes
	xor edi,edi					;index in active

	.removeNode:

		cmp edi,ecx
		jge .endRemoveNode

		mov ebx,[active + edi*4]		;get the index of the current node in active 
			
		
		cmp ebx,eax			;check if the index is the same as the given index
		jne .next

		

		 mov esi, edi
			.shiftNodeLoop:
    			inc esi		;increase index
    			cmp esi, ecx		;check if the end of the file was reached
    			jge .shiftNodeLoopEnd


   				mov edx, [active + esi*4]		;get the value of the current node
    			mov [active + (esi-1)*4], edx	;set the value of the previous node
   				jmp .shiftNodeLoop

			.shiftNodeLoopEnd:
    		dec dword [activeCount]			;decrese active count
    		jmp .endRemoveNode
			
			.next:
			inc edi
    		jmp .removeNode

	.endRemoveNode:

	popa
	

ret


;Generates the code of each charachter recursively, eax will be the current node index, ebx the code and cl the code length
GenerateCodes:
	pusha

		
		mov edx,eax			;save index
		shl edx,4 			;get the node offset
		mov esi,[huffmannTree + edx + 4]	;get the charachter value

		cmp esi,-1			;check if the node is a charachter
		je .notCharachter

		mov [codes + esi* 4],ebx
		mov[codeLenght + esi],cl
		jmp .charachterFound


		

		.notCharachter:

			push ebx		;save the code
			push ecx			;save code length

			mov eax,[huffmannTree + edx + 8]			;get left child index
			shl ebx,1		;add 0 to code
			inc cl			;increse code size
			call GenerateCodes			;get the code of the left child


			pop ecx		;restore code length
			pop ebx		;restore code


			push ebx
			push ecx

			mov eax,[huffmannTree + edx + 12]			;get the index of the right node
			shl ebx,1			;shift right to create space
			add ebx,1			;add 1 to the code
			inc cl				;increase code size
			call GenerateCodes			;get the code for the right child
			

			pop ecx
			pop ebx

	.charachterFound:

	popa
ret

;Builds the Huffmann tree
BuildTree:

	pusha

		
		xor ecx, ecx


		mov [activeCount], dword 0
		xor ecx,ecx				;ecx will be the index for the frequency array
		xor esi,esi				;esi will be the node counter

		.findActiveNodes:

			

			cmp ecx,257				;loop through the frequency array
			je .endFindActiveNodes

			
			
			

			mov ebx,[freq + ecx * 4]	;get frequency

			cmp	ebx,0					;check if the frequency is greater than 0
			je .ZeroFrequency

			;debug --------------------------------

			;mov eax,ebx			;write out the frequency and ascii value of the charachter in the node
			;call io_writeint
			;call NewLine
			;mov eax,ecx
			;call mio_writechar
			;call NewLine
			;call NewLine

			
			

			mov eax,esi
			shl eax,4
			
			

			mov[huffmannTree + eax],ebx				;save frequency
			mov[huffmannTree + eax + 4],ecx			;save ascii value of the charachter	
			mov[huffmannTree + eax + 8], dword -1		;set left pointer to 0
			mov[huffmannTree + eax + 12],dword -1		;set right pointer to 0


			

			mov eax,[activeCount]
			mov[active + eax*4],esi

			inc esi						;increase node cout
			inc eax
			mov [activeCount],eax		;increase active count

			.ZeroFrequency:

			inc ecx						;increase index
			jmp .findActiveNodes
		.endFindActiveNodes:
		
		
		
		mov [nodeCount],esi

		

		.BuildTreeLoop:

			cmp [activeCount],dword 1					;check if there are less or equal to 1 active nodes
			jng .BuildTreeLoopEnd

			
			
			call FindSmallestActiveNode		;move the index of the two smallest nodes into eax and ebx respectilvely
			mov [nodeA], eax

			call RemoveFromActive

			

			call FindSmallestActiveNode
			mov [nodeB], eax
			
			call RemoveFromActive
			
			
			mov eax,[nodeA]
			shl eax,4
			mov edx,[huffmannTree + eax]		;get the frequency of the smallest node

			mov eax,[nodeB]
			shl eax,4
			mov ecx,[huffmannTree + eax]		;get the frequency of the second smallest node

			add edx,ecx				;add the frequencies together

			mov esi,[nodeCount]
			mov [newNode],esi

			mov eax,esi		;eax will be the index of the new node
			shl eax,4
			mov[huffmannTree + eax],edx			;save the frequency of the new node

			mov ecx,[nodeA]
			mov [huffmannTree + eax + 8],ecx			;save index of the smallest node
			mov ecx,[nodeB]
			mov [huffmannTree + eax + 12],ecx		;save index of the second smallest node

			mov[huffmannTree + eax + 4], dword -1				;mark that the node is not a charachter
			
			

			.addNodeToActive:			;add the index of the new node to the active list

			mov eax,[activeCount]
			mov ecx,[newNode]
			mov [active + eax*4],ecx
			inc dword [activeCount]

			inc esi				;increase node number
			mov [nodeCount],esi

			jmp	.BuildTreeLoop
		.BuildTreeLoopEnd:

	

		mov eax,esi
		dec eax				;get the index of the top node
		xor ebx,ebx			;clear ebx this will hold the code of the charachter		
		xor ecx,ecx			;clear ecx this will hold the number of digits in the code
		call GenerateCodes

	popa

ret



;uses FilePath to create the output path
GetOutputPath:
	pusha

	

	xor ecx,ecx			;clear ecx, this will be the index

	mov edi, outputPath
	mov esi, FilePath
	call StrCat

	call StrLen

	mov ecx,eax
	

	.getPathLoop:

		mov bl,[outputPath + ecx]

	

		cmp bl,'.'
		je .endGetPath

		mov [outputPath + ecx], byte 0
		dec ecx

		jmp .getPathLoop
	.endGetPath:

	inc ecx

	mov [outputPath + ecx], byte 0

	
	

	popa

ret

;Encodes the file
Encode:
	pusha

	

	call GetOutputPath		;get the file path

	mov edi,outputPath
	mov esi,encodedExtension

	call StrCat



	mov eax,outputPath	;set file path
	mov ebx,1				;select write mode

	
		
	
	call fio_open
	jc .error
				;call open function
	mov[outputHandle],eax	;save file handle

	mov ebx,extension		;get extension
	mov ecx, 4					;set size to 4
	call fio_write				;write extension
	

	mov eax,[outputHandle]	;get file handle
	mov ebx,freq			;get the frequency table
	mov ecx,1028			;set the size of the array (257*4)
	call fio_write			;write codes array into the output file

	mov eax,[outputHandle]	;get file handle
	mov ebx,bytesToRead		;get the nr of bytes in the original file
	mov ecx,4				;ste size to 4 (beacuse dword)
	call fio_write			;write codes array into the output file

	mov eax,[outputHandle]	;get ouptut handle
	mov ebx,fileType		;get filetype pointer
	mov ecx,10				;copy 10 bytes
	call fio_write
	




	xor edx,edx		;clear ecx this will be the index

	.EncodeFile:

		;int3
		cmp edx,[bytesToRead]
		je .doneEncoding

		movzx eax, byte [buffer + edx]		;get charachter

		mov ebx,[codes + eax*4]			;get the code of the charachter
		mov edi,[codeLenght + eax]		;get the code lenght

		mov ecx,32		;move 32 into cl beacuse the code is stored in a dword
		sub ecx,edi		;get the size of the surplus 0 at the start

		shl ebx,cl		;shift out the plus zeros
		
		xor ecx,ecx			;clear ecx
		mov cl, [codeLenght + eax]		;get the lenght of the code 
		

		.shiftBitsLoop:
			;int3
			mov edi,bitCount
			cmp [bitCount], byte 8
			jne .getBits

			mov [bitCount], byte 0	;clear bitcount

			push eax	
			push ebx
			push ecx
			push edx

			mov eax,[outputHandle]	;get handle
			mov ebx,bitBuffer			;get bit array
			mov ecx,1					;set 1 for 1 byte
			call fio_write

			
			mov [bitBuffer], byte 0
			pop edx
			pop ecx
			pop ebx
			pop eax

			.getBits:

			movzx eax, byte [bitBuffer]	;get bit buffer
			shl eax,1	
			shl ebx,1				;shift left the valid code digits, get the first digit in carry
			adc eax,0				;add with carry to esi

			mov [bitBuffer],al	;save bitBuffer

			inc byte [bitCount]	;increment bit coun

			dec ecx
			cmp ecx,0
			jg .shiftBitsLoop
			
		


		inc edx
		jmp .EncodeFile
	.doneEncoding:

		;int3
		mov eax,256                     ; EOF symbol index
		mov ebx,[codes + eax*4]          ; Huffman code
		mov edi,[codeLenght + eax]       ; code length

		mov ecx,32						;get 32
		sub ecx,edi						;calculate how many bits to shift
		shl ebx,cl                      ; shift bits to get bits with value

		xor ecx,ecx
		mov cl,[codeLenght + eax]						;get nr of bits  

	.shiftBitsLoopEOF:	

	mov edi,bitCount
			cmp [bitCount], byte 8
			jne .getBitsEOF

			mov [bitCount], byte 0	;clear bitcount

			push eax	
			push ebx
			push ecx
			push edx

			mov eax,[outputHandle]	;get handle
			mov ebx,bitBuffer			;get bit array
			mov ecx,1					;set 1 for 1 byte
			call fio_write

			mov [bitBuffer], byte 0
			pop edx
			pop ecx
			pop ebx
			pop eax

			.getBitsEOF:

			movzx eax, byte [bitBuffer]	;get bit buffer
			shl eax,1	
			shl ebx,1				;shift left the valid code digits, get the first digit in carry
			adc eax,0				;add with carry to esi

			mov [bitBuffer],al	;save bitBuffer

			inc byte [bitCount]	;increment bit coun

			dec ecx
			cmp ecx,0
			jg .shiftBitsLoopEOF


	cmp byte [bitCount], 0		;if the bitcount is not 0 write remaining bit
	je .skipLastByte


	mov al,[bitBuffer]
	mov cl,8
	sub cl,[bitCount]       ; number of empty bits
	shl al,cl               ; shift valid bits to front
	mov [bitBuffer],al

					
	mov eax,[outputHandle]		;get handle
	mov ebx,bitBuffer			;get bit array
	mov ecx,1					;set 1 for 1 bit
	call fio_write
	
	
	.skipLastByte:

	mov eax,[outputHandle]		;get the handle of output
	call fio_close				;close output file

	popa

	ret

	.error:

	mov esi,Error
	call WriteStr


ret

;reads the frequencytable and the bytes form a compressed file
ReadFromCompressedFile:
	pusha

	mov eax,FilePath		;get file path
	mov ebx,0				;seet to read mode
	call fio_open

	push eax
	mov ebx,extensionTest
	mov ecx,4
	call fio_read


	;check if the file is a HUFF file create by the program
	mov esi,extension
	mov edi,extensionTest
	call StrCmp

	cmp eax,0		;if the strings are equal continue
	je .ok
	pop eax
	mov eax,err_notHuff
	call io_writestr
	call fio_close		;close file
	jmp error_exit

	.ok:
	
	pop eax
	mov ebx,freq			;get the pointer to freq 
	mov ecx,1028			;read 256*4 bytes
	call fio_read

	mov ebx,originalSize	;get a pointer to originalSize
	mov ecx,4				;set size to 4 ( beacuse dword)  
	call fio_read

	mov ebx,fileType		;get filetype pointer
	mov ecx,10				;read 10 bytes
	call fio_read

	mov ebx,buffer			;get buffer pointer
	mov ecx,[bufferSize]	;seet the size of the buffer
	call fio_read

	mov [bytesToRead],edx		;set the bytes read

	call fio_close			;close file

	popa

ret


;decompresses the compressed file
DecompressFile:


	pusha

	call GetOutputPath


	mov edi,outputPath		;concatenate file type
	mov esi,fileType
	call StrCat

	;mov eax,outputPath
	;call io_writestr

	mov eax,fileType
	call io_writestr

	mov eax,outputPath			;get output path
	mov ebx,1 					;set to write mode
	call fio_open		

	mov [outputHandle],eax		;save output handle
	

	xor ecx,ecx				;clear ecx, this will hold the number of written bytes
	xor esi,esi				;esi will be the index for the buffer
	mov edi,[nodeCount]		;get the index of the root note
	dec edi					
	.getBytes:

						

		cmp [bitCount],byte 0			;check if the bit buffer is empty
		jne .notEmptyBitBuffer

			

			push eax
	
			mov al,[buffer + esi]		;get next 8 bits
			mov [bitBuffer],al			;save the bits to bitbuffer
			mov [bitCount],byte 8			;reset bit count

			inc esi
			pop eax

		.notEmptyBitBuffer:

		xor eax,eax						;clear eax

		mov bl,[bitBuffer]				;get bit buffer
		shl bl,1						;shift bit buffer left by one, get the bit into carry
		adc eax,0						;add bit to eax

		mov [bitBuffer],bl				;save shifted byte
		dec byte [bitCount]			;decrease bit counter

		cmp eax,0						;take the corresponding path	
		jne .rightPath

		mov edx,edi
		shl edx,4			;set offset

		mov ebx,[huffmannTree + edx + 8]		;get the index of the left element

		mov edi,ebx
		mov edx,edi
		shl edx,4								;update current index
		mov ebx,[huffmannTree + edx + 4 ]	;get charachter

		cmp ebx,-1			;check if the node is a charachter node, important keep as ebx since the value ff represents the of char
		je .next

		jmp .charachter			
		.rightPath:

		mov edx,edi
		shl edx,4
		mov ebx,[huffmannTree + edx + 12]		;get the index of the right element

		mov edi,ebx	
		mov edx,edi
		shl edx,4							;update current index
		mov ebx,[huffmannTree + edx + 4 ]	;get charachter

		cmp ebx,-1			;check if the node is a charachter node
		je .next

		.charachter:
		;int3
		cmp ebx,256        ; check for eof
		je .endBytes

		mov eax,[outputHandle]			;get output handle
		mov [charachterByte],bl			;save charachter byte

		
		push ecx
		mov ebx,charachterByte		;get charachterByte
		mov ecx, 1					;set size to 1
		call fio_write				;write charachter

		pop ecx

		mov edi,[nodeCount]			;reset to root node
		dec edi
		.next:



		jmp .getBytes

	.endBytes:
	
	mov eax,[outputHandle]			;get output handle
	call fio_close


	popa
ret

;saves the file type of the input file into fileType
GetFileType:
	pusha

	mov esi,FilePath
	call StrLen
	mov ecx,eax				; index of the terminating 0

	.findDot:				; scan backwards for the last '.', stop at a backslash
		test ecx,ecx
		jz .noExtension
		dec ecx
		mov bl,[FilePath + ecx]
		cmp bl,'\'
		je .noExtension
		cmp bl,'.'
		jne .findDot

	inc ecx					; skip the dot itself
	xor edx,edx
	.copy:
		cmp edx,9			; fileType holds 10 bytes: max 9 chars + terminator
		je .terminate
		mov bl,[FilePath + ecx]
		test bl,bl
		jz .terminate
		mov [fileType + edx],bl
		inc ecx
		inc edx
		jmp .copy
	.terminate:
	mov byte [fileType + edx],0
	jmp .done

	.noExtension:
	mov byte [fileType],0
	.done:

	popa
ret
main:

	

	call GetFilePath		;get the filepath and the app mode

	

	mov bl,[appMode]		;get the appmode

	cmp bl,"d"				;check if the appmode is decompress
	je .decompress

	mov dword [bytesToRead], 0		;set the bytes of the file to 0

	call ReadFromFile				;call the file reader function

	mov esi,msg_read
	call WriteStr


	call GetFileType			;saves the file type into fileType

	
	
	call SetFreq			;set frequency table

	mov esi,msg_freq
	call WriteStr


	call BuildTree			;build the and get the codes

	mov esi,msg_tree
	call WriteStr

	call Encode				;encode the file
	
	mov esi,msg_encoded
	call WriteStr
	
	mov esi,ok
	call WriteStr



	ret


	.decompress:

		call ReadFromCompressedFile		;read buffer and freq table

		mov esi,msg_read
		call WriteStr

		call BuildTree					;build up the tree from the freq table

		mov esi,msg_tree
		call WriteStr


		call DecompressFile				;decompress the file

		mov esi,msg_decomp
		call WriteStr

	mov esi,ok
	call WriteStr



ret

;called if the program reaches an error
error_exit:
    mov   eax, 1            ; sys_exit
    int   0x80


section .data

Error db 'Error',0			;error message



ok db 'ok',0				;ok message
encodedExtension db 'huff',0

extension db 'HUFF',0

err_path db 'The given file does not exist',0
err_notHuff db 'The given file is not a .huff file',0
err_Huff db 'The given file is a .huff file and it cannot be encoded',0
msg_read db 'File read	',0
msg_freq db 'Frequency table build	',0
msg_tree db 'Tree Built	',0
msg_encoded db 'File encoded	',0
msg_decomp db 'File decompressed	',0

activeCount dd 0	;number of active nodes		

nodeA dd 0			;smallest node
nodeB dd 0			;second smallest node
newNode dd 0		;newly created node

OutputExtension db 'huf',0	

bufferSize dd 100000000			;the amout of maximum bytes

bitBuffer db 0			;bit buffer, if its full gets copied to file
bitCount db 0			;couonts the nr of bits in the bitbuffer

section .bss

extensionTest resb 5	;when decompressing stores the first 4 bytes of the file and compares to the extension
appMode resb 1 			;stores the app mode charachter c for compress(or any charachter), d for decomplress
bytesToRead resd 1		;stores how many bytes were read 
FilePath resb 100		;stores the file path
buffer resb 100000000	;the buffer stores the bytes read from the file
freq resd 257			;frequency table

active resd 512			;the indexes of the active nodes

originalSize resd 1

smallest resd 1			
secmdSmallest resd 1

fileType resb 10			;stores the file extension

nodeCount resd 1		;number of nodes

huffmannTree resb 514* 16		;stores the tree in this format: dword frequency,
																;dword charachter(-1 if its not a charachter),
																;dword left node index (-1 if the node is a char),
																;dword right index (-1 if the node is a char) 

codes resd 257				;stores the codes of the charachters
codeLenght resb 257		;stores the lenght of the codes



outputHandle resd 1			;stores the output files file handle
outputPath resb 100			;stores the output path string

charachterByte	resb 1 		;the byte of the charachter