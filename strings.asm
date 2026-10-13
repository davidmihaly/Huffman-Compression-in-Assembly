%include 'mio.inc'


global StrLen
global StrCat
global StrUpper
global StrLower
global StrCompact

section .text

;--------------------------------------------------------------------------------

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
 
;--------------------------------------------------------------------------------
 
;makes all the lowercase letters in the string given by esi uppercase
StrUpper:

	pusha
	;clear registers
	xor eax,eax
	xor ebx,ebx
	xor ecx,ecx

	;iterate through elements
	.next:
	
		mov bl,[esi + ecx]
		
		cmp bl,0
		je .end
		
		;if the element is bigger than a jmp
		cmp bl, 'a'
		jge .bigger
		
		.continue:
		
		inc ecx	
	
	jmp .next

	.end:
	popa
 ret
 
 ;if the element is smaller than z jmp to lowercase else continue 
 .bigger:
 
	cmp bl,'z'
	jle .lowerCase
	
	jmp .continue

	
;convert a lowercase letter into uppercase
.lowerCase:
	
	sub ebx,32
	mov [esi + ecx], bl
	
	jmp .continue

;--------------------------------------------------------------------------------
	
;makes all the uppercase letter in the string given by esi lowercase
StrLower:

	pusha
	;clear registers
	xor eax,eax
	xor ebx,ebx
	xor ecx,ecx

	;iterate through elements
	.next:
	
		mov bl,[esi + ecx]
		
		cmp bl,0
		je .end
		
		;if the element is bigger than A jmp
		cmp bl, 'A'
		jge .bigger
		
		.continue:
		
		inc ecx	
	
	jmp .next

	.end:
	
	popa
 ret
 
 ;if the element is smaller than Z jumpt to uppercase else continue
 .bigger:
 
	cmp bl,'Z'
	jle .upperCase
	
	jmp .continue

;convert elements to lowercase
.upperCase:
	
	add ebx,32
	mov [esi + ecx], bl
	
	jmp .continue

;--------------------------------------------------------------------------------

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

;--------------------------------------------------------------------------------

;copies and compacts esi to edi
StrCompact:

	pusha
	;clear the string given by edi
	

	
	;clears ecx,edx
	xor ecx,ecx
	xor edx,edx
	
	;reads chars from esi
	.next2:
		
		mov bl,[esi + ecx]
		
		;if the charchter is a white charachter,skip saving it
		cmp bl,0
		je .end2
		
		cmp bl, ' '
		je .unsaved
		
		cmp bl,9
		je .unsaved
		
		cmp bl,10
		je .unsaved
		
		cmp bl,13
		je .unsaved
		
		;save charachter, and increase the new array's index 
		mov [edi + edx], bl
		inc edx
		.unsaved:
		
		;increas the old array's index
		inc ecx
		jmp .next2
	
	.end2:
	
	;clear the string given by edi
	
	
	
	.next:
		
		mov bl,[edi + edx]
		
		cmp bl,0
		je .end
		
		mov [edi + edx], byte 0
		
		inc edx
		jmp .next
	.end:
	
	


popa
ret

