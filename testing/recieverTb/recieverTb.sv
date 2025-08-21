`include "uartUtil.sv"
/* verilator lint_off DECLFILENAME */
interface rxIf;
    logic clk, rst;
    logic recieverInput; 
    logic[7:0] byteRecieved;
    logic done;
    /* verilator lint_off UNUSEDSIGNAL */
    logic[7:0] txLine; 
    /* verilator lint_on UNUSEDSIGNAL */
    logic [7:0] expected_shift;
endinterface
module recieverTb;

    // "virtual interface" to get verilator to play nice with the test framework
    rxIf vIf();
    import testFramework::*;

    parameter int uartFrameSize = 8;

    reciever dut
    (
        .clk(vIf.clk),
        .rst(vIf.rst),
        .recieverInput(vIf.recieverInput),
        .byteRecieved(vIf.byteRecieved),
        .done(vIf.done)
    );

    initial
    begin
        vIf.clk = 1'b0;
        forever #20 vIf.clk = ~vIf.clk;
    end

    `TEST_TASK(recieverTb, vaildate_reset_on_idle_state)
        @(posedge vIf.clk)
            vIf.rst = 1'b1; 
            vIf.recieverInput = 1'b1;
        @(posedge vIf.clk);
            vIf.rst = 1'b0; 
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
            repeat (4) @(posedge vIf.clk); // wait a few cycles
            vIf.rst = 1'b1; 
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, vaildate_reset_on_idle_state)

    // logic[7:0] txLine = 8'b10101010;
    `TEST_TASK(recieverTb, validate_start_state_on_start_bit)
        @(posedge vIf.clk)
            vIf.rst = 1'b1; 
            vIf.recieverInput = 1'b1;
        @(posedge vIf.clk);
            vIf.rst = 1'b0; 
            vIf.recieverInput = 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk);
            vIf.recieverInput = 1'b0;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk); // nothing should be shifted in yet
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk);
    `END_TEST_TASK(recieverTb, validate_start_state_on_start_bit)

    `TEST_TASK(recieverTb, validate_send_state_transition)
        @(posedge vIf.clk)
            vIf.rst = 1'b1;
            vIf.recieverInput = 1'b1;
            vIf.txLine = 8'b10101010;
        @(posedge vIf.clk)
            vIf.rst = 1'b0;
            vIf.recieverInput = 1'b0;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk)
            vIf.recieverInput = vIf.txLine[0];
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk)
            vIf.recieverInput = vIf.txLine[1];
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd1, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, {24'b0, 8'b00000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk)
            vIf.recieverInput = vIf.txLine[2];
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd2, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, {24'b0, 8'b10000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_send_state_transition)

    `TEST_TASK(recieverTb, validate_stop_state_transition_and_recieve_one_byte)
        @(posedge vIf.clk)
            vIf.rst = 1'b1;
            vIf.recieverInput = 1'b1;
            vIf.txLine = 8'b10101010;
        @(posedge vIf.clk)
            vIf.rst = 1'b0;
            vIf.recieverInput = 1'b0;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 9; iIter++)
        begin
            @(posedge vIf.clk)
                if(iIter == 0)
                begin
                    vIf.recieverInput = vIf.txLine[iIter];
                    #1
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                else if(iIter == 8)
                begin
                    vIf.recieverInput = 1'b1;
                    #1
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
                end
                else
                begin
                    vIf.recieverInput = vIf.txLine[iIter];
                    #1
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, iIter, `REPORT(), "binary");
                vIf.expected_shift = vIf.txLine << (uartFrameSize-iIter);
                EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, {24'b0, vIf.expected_shift}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        end
        @(posedge vIf.clk)
            vIf.recieverInput = 1;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd2, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.byteRecieved}, {24'b0, vIf.txLine}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b1, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_stop_state_transition_and_recieve_one_byte)

    `TEST_TASK(recieverTb, validate_reset_on_start_state)
        @(posedge vIf.clk)
            vIf.rst = 1'b1;
            vIf.recieverInput = 1'b1;
            vIf.txLine = 8'b10101010;
        @(posedge vIf.clk)
            vIf.rst = 1'b0;
            vIf.recieverInput = 1'b0;
    `END_TEST_TASK(recieverTb, validate_reset_on_start_state)

    initial
    begin
        testFramework::TestManager::runAllTasks();
        $finish;
    end  
endmodule
/* verilator lint_on DECLFILENAME */
