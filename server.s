.intel_syntax noprefix
.globl _start

.section .text

_start:
	# socket_fd = socket(AF_INET, SOCK_STREAM, PF_UNSPEC )
	mov rdi, 2 #AF_INET
	mov rsi, 1 #SOCK_STREAM
	mov rdx, 0 #PF_UNSPECT
	mov rax, 41 #sys_socket
	syscall
	
	# socket_fd stored into rbx
	mov rbx, rax 

	# bind(socket_fd, ipv4_sockaddr, 16)
	mov rdi, rbx #socket_fd
	mov rsi, OFFSET ipv4_sockaddr
	mov rdx, 16  #size
	mov rax, 49  #sys_bind
	syscall

	# listen(socket_fd, 0)
	mov rdi, rbx #socket_fd
	mov rsi, 0   #backlog
	mov rax, 50  #sys_listen
	syscall

accept:
	# client_fd = accept(socket_fd, null, null)
	mov rdi, rbx #socket_fd
	mov rsi, 0
	mov rdx, 0
	mov rax, 43  #sys_accept
	syscall

	# client_fd stored in r12
	mov r12, rax

	# fork()
	mov rax, 57
	syscall

	# separate task comparing return [pid]
	# parent pov: [return v pid=child_pid]
	# child pov: [return value pid=0]
	cmp rax, 0
	je child
	jmp parent

parent:
	# close(client_fd)
	mov rdi, r12 #client_fd
	mov rax, 3
	syscall
	jmp accept

child:
	# close(socket_fd)
	mov rdi, rbx #socket_fd
	mov rax, 3
	syscall

	#Client: read(client_fd, buffer, buffer_size)
	mov rdi, r12 #client_fd
	mov rsi, OFFSET buffer
	mov rdx, [buffer_length]
	mov rax, 0 #sys_read
	syscall

	mov r8, rax

	#Server: get_file_path, get_request_method
	mov r13, OFFSET buffer
	mov r9, r13
	add r9, 6

get_file_path:
	cmp byte ptr [r13], ' '
	je found_space
	inc r13
	jmp get_file_path
	#r13 stored the beginning of the file_path

found_space:
	cmp byte ptr [r9], ' '
	je get_request_method
	inc r9
	jmp found_space

get_request_method:
	inc r13
	mov byte ptr [r9], 0

	mov rax, OFFSET buffer
	cmp word ptr[rax], 0x4547
	je get
	cmp word ptr[rax], 0x4F50
	je post

	# Write(client_fd, error_response, 35)
	mov rdi, r12
	mov rsi, OFFSET server_response_error
	mov rdx, 35
	mov rax, 1
	syscall
	
	jmp exit

post:
	# Open(file_path, O_CREAT | O_WRONLY, 0777)
	mov rdi, r13
	mov rsi, 65
	mov rdx, 511
	mov rax, 2
	syscall

	#file_fd stored in r15
	mov r15, rax

	#cuz r9 is closer to file content
	mov rax, OFFSET buffer
	mov rbx, 0

file_content:
   cmp dword ptr [rax], 0x0a0d0a0d
   je done
   inc rax
   inc rbx
   jmp file_content

done:
	add rax, 4
	add rbx, 4
	sub r8, rbx

	# Write(file_fd, buffer, buffer_length)
	mov rdi, r15
	mov rsi, rax
	mov rdx, r8
	mov rax, 1
	syscall

	# Write(client_fd, server_response, 19)
	mov rdi, r12
	mov rsi, OFFSET server_response
	mov rdx, 19
	mov rax, 1
	syscall

	# Close(file_fd)
	mov rdi, r15
	mov rax, 3
	syscall

	jmp exit

get:
	# Open(file_path, O_RDONLY, MODE)
	mov rdi, r13
	mov rsi, 0
	mov rdx, 0
	mov rax, 2
	syscall

	#file_fd stored in r15
	mov r15, rax

	# Read(file_fd, file_buffer, file_buffer_size)
	mov rdi, r15 #file_fd
	mov rsi, OFFSET file_buffer
	mov rdx, 1024
	mov rax, 0
	syscall

	#file_size stored in r14
	mov r14, rax

	# Close(file_fd)
	mov rdi, r15
	mov rax, 3

	# Write(client_fd, server_response, 19)
	mov rdi, r12
	mov rsi, OFFSET server_response
	mov rdx, 19
	mov rax, 1
	syscall

	# Write(client_fd, file_buffer, file_buffer_size)
	mov rdi, r12
	mov rsi, OFFSET file_buffer
	mov rdx, r14
	mov rax, 1
	syscall
	jmp exit

exit:
	# Close(client_fd)
	mov rdi, r12
	mov rax, 3
	syscall

	# Exit(0)
	mov rdi, 0
	mov rax, 60
	syscall

.section .data

ipv4_sockaddr:
	.short 2
	.short 0x5000
	.4byte 0
	.8byte 0
	

server_response:
	.string "HTTP/1.0 200 OK\r\n\r\n"

server_response_error:
	.string "HTTP/1.0 405 Method Not Allowed\r\n\r\n"

buffer: .space 1024, 0x00
buffer_length: .quad 0x0000000000000400

file_buffer:
	.space 1024, 0x00
