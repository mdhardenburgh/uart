`ifndef UART_UTIL
`define UART_UTIL
package uartUtil;
    typedef enum logic[1:0] 
    {
        IDLE,
        START,
        SEND,
        STOP
    } states_t;
    parameter int uartFrameSize = 8;
endpackage
`endif
