# Overview

This is a mini-project, where the goal is to build a web server that is able to respond to multiple requests at the same time, designed for a specific task, yet written in assembly language, which allows for more control over the hardware, takes up less space, and runs a lot quicker.

This type of project can be applied to embedded environments, creating compact applications in a limited environment. Or in specific programs where you don't need to use a complete library.

## Installation

Use the portable GNU assembler [AS](https://man7.org/linux/man-pages/man1/as.1.html) to build it.

```bash
as -o server.o server.s && ld -o server server.o
```

## Usage

Server:
<img src="https://github.com/Jordan-R23/http-server-assembly/blob/main/server.gif" width="512" >

Client:
<img src="https://github.com/Jordan-R23/http-server-assembly/blob/main/client.gif" width="512" >
