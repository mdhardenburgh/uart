`include "uartUtil.sv"
module transmitter
(
    input logic clk, // from baud rate generator
    input logic rst, // from system
    input logic send, // from buffer
    input logic[7:0] byteToLoad, // from buffer
    output logic transmitOutput, // to FTDI uart
    output logic done // to buffer, ready for next byte
);

    uartUtil::states_t stateCounter;
    uartUtil::states_t nextState;
    logic[2:0] sendCounter;

    always_ff @(posedge clk) 
    begin : incrementState
        if(rst)
        begin
            stateCounter <= uartUtil::IDLE;
        end
        else
        begin
            stateCounter <= nextState;
        end
    end

    always_ff @(posedge clk)
    begin: sendCounterLogic
        if(rst)
        begin
            sendCounter <= 3'b0;
        end
        else
        begin
            case(stateCounter)
                uartUtil::IDLE: sendCounter <= 3'b0;
                uartUtil::START: sendCounter <= 3'b0;
                uartUtil::SEND: sendCounter <= sendCounter + 1;
                uartUtil::STOP: sendCounter <= 3'b0;
            endcase
        end
    end

    always_comb 
    begin: nextStateLogic
        case(stateCounter)
            uartUtil::IDLE:
            begin
                if(send)
                begin
                    nextState = uartUtil::START;
                end
                else
                begin
                    nextState = uartUtil::IDLE;
                end
            end
            uartUtil::START:
            begin
                nextState = uartUtil::SEND;
            end
            uartUtil::SEND:
            begin
                if(sendCounter == 3'd7)
                begin
                    nextState = uartUtil::STOP;
                end
                else
                begin
                    nextState = uartUtil::SEND;
                end
            end
            uartUtil::STOP:
            begin
                if(send)
                begin
                    nextState = uartUtil::START;
                end
                else
                begin
                    nextState = uartUtil::IDLE;
                end
            end
        endcase
    end

    always_comb
    begin: outputLogic
        case(stateCounter)
            uartUtil::IDLE:
            begin
                transmitOutput = 1'b1;
                done = 1'b0;
            end
            uartUtil::START:
            begin
                transmitOutput = 1'b0;
                done = 1'b0;
            end
            uartUtil::SEND:
            begin
                transmitOutput = byteToLoad[sendCounter];
                done = 1'b0;
            end
            uartUtil::STOP:
            begin
                transmitOutput = 1'b1;
                done = 1'b1;
            end
        endcase
    end
endmodule
