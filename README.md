# UART Transceiver

Simple UART transciever.

## Introduction

This is designed to be a drop in IP core for a simple UART transciever. 
To include this into your project, simply add the following line to your greater 
cmake project: `target_link_libraries(${PROJECT_NAME} PRIVATE svTest)`

### FT2232HQ to Artix-7 connections

PC     FPGA
TXD -> C4 transmitter output
RXD <- D4 reciever input
CTS <- D3 clear to send handshake output
RTS -> E5 ready to send handshake output

The Ready to Send (RTS) signal is asserted by the PC, telling the UART client
that it is ready to send the client data

The Clear to Send (CTS) signal is asserted by the UART client and tells the host that
its buffers have room for data. The host only drives data to the client through
the TXD line when both CTS and RTS are asserted.

## Transmitter

Below is the state transition diagram for our transmitter:

```mermaid
stateDiagram-v2
    %% Declare each state with a multi‐line label
    state "IDLE, transmitOutput == 1, done == 0" as IDLE
    state "START, transmitOutput == 0, done == 0" as START
    state "SEND, transmitOutput == [0 ... 7], done == 0" as SEND
    state "STOP, transmitOutput == 1, done == 1" as STOP

    IDLE --> IDLE : send == 0, rst == 1
    IDLE --> START : send == 1
    START --> SEND : 
    START --> IDLE : rst == 1
    SEND --> SEND : while sendCounter < 7
    SEND --> IDLE : rst == 1
    SEND --> STOP : sendCounter == 7
    STOP --> IDLE : 
```

## Reciever

## Regiser Map

Below is a register map. Each register is 32-bits wide and relative to the base
address given by the system integrator.

| offset | Name    | Type | Description      |
|--------|---------|------|------------------|
| 0x000  | UARTCTL | R/W  | Control Register |

## Testing

Test benches are located in the `testing` directory and use svTest. Cloning of
svTest is not required and is done as part of the transmitterTb or reciverTb
build call.

To build the tests, at the root level:
```
$ cmake -S . -B build
$ cmake --build build
```

To build a specific test:
```
$ cmake -S . -B build
$ cmake --build build --target transmitterTb
$ cmake --build build --target recieverTb
```

## License

Copyright (C) 2025 Matthew Hardenburgh

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
