`include "uartUtil.sv"
module reciever
(
    input logic clk,
    input logic rst,
    input logic recieverInput,
    output logic[7:0] byteRecieved,
    output logic done
);
    uartUtil::states_t stateCounter;
    uartUtil::states_t nextState;

    logic[3:0] recieveCounter;
    logic[7:0] recievedInput;

    assign recievedInput = ({recieverInput, 7'b0}|(byteRecieved>>1));

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
    begin: recieveCounterLogic
        if(rst)
        begin
            recieveCounter <= 4'b0;
        end
        else
        begin
            unique case(stateCounter)
                uartUtil::START, uartUtil::SEND: 
                begin
                    if(recieveCounter < 8)
                    begin
                        recieveCounter <= recieveCounter + 1;
                    end
                    else
                    begin
                        recieveCounter <= recieveCounter;
                    end
                end
                uartUtil::IDLE, uartUtil::STOP:
                begin
                    recieveCounter <= 4'b0;
                end
            endcase
        end
    end

    always_ff@(posedge clk)
    begin:shiftRegister
        if(rst)
        begin
            byteRecieved <= 8'h00;
        end
        else
        begin
            unique case(stateCounter)
                uartUtil::START: 
                begin
                    byteRecieved <= recievedInput;
                end
                uartUtil::SEND:
                begin
                    if((recieveCounter > 4'd7))
                    begin
                        byteRecieved <= byteRecieved;
                    end
                    else
                    begin
                        byteRecieved <= recievedInput;
                    end
                end
                uartUtil::IDLE, uartUtil::STOP:
                begin
                    byteRecieved <= byteRecieved;
                end
            endcase
        end
    end// 01000000, 

    always_comb
    begin: nextStateLogic
        if(rst)
        begin
            nextState = uartUtil::IDLE;
        end
        else
        begin
            unique case(stateCounter)
                uartUtil::IDLE:
                begin
                    if(recieverInput == 1'b0)
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
                    if((recieveCounter > 4'd7) && (recieverInput == 1'b1))
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
                    if(recieverInput == 1'b0)
                    begin
                        nextState = uartUtil::START;
                    end
                    else
                    begin
                        nextState = uartUtil::IDLE;
                    end
                end
                default:
                begin
                    nextState = uartUtil::IDLE;
                end
            endcase
        end
    end

    always_comb
    begin: outputLogic
        if(stateCounter == uartUtil::STOP)
        begin
            done = 1'b1;
        end
        else
        begin
            done = 1'b0;
        end
    end
endmodule
