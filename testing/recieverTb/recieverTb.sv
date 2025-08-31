`include "uartUtil.sv"

/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSEDSIGNAL */
interface rxIf;
    logic clk, rst;
    logic recieverInput; 
    logic[7:0] byteRecieved;
    logic done;

    /*
     * Clocking block is a TB-side construct that tells the simulator when to 
     * sample and drive the existing interface signals relative to vIf.clk.
     */
    /* verilator lint_off UNDRIVEN */
    clocking cb @(posedge clk);
        // Read DUT outputs at the edge; drive TB outputs just after the edge
        default input #0 output #0;
        output rst, recieverInput;      // TB drives these (DUT inputs)
        input  byteRecieved, done;      // TB samples these (DUT outputs)
    endclocking
    /* verilator lint_on UNDRIVEN */

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
        @(vIf.cb)
            vIf.cb.rst <= 1'b1; 
            vIf.cb.recieverInput <= 1'b1;
        @(vIf.cb);
            vIf.cb.rst <= 1'b0;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        repeat (4) @(vIf.cb); // wait a few cycles
            vIf.cb.rst <= 1'b1; 
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, vaildate_reset_on_idle_state)

    `TEST_TASK(recieverTb, validate_start_state_on_start_bit)
        @(vIf.cb)
            vIf.cb.rst <= 1'b1; 
            vIf.cb.recieverInput <= 1'b1;
        @(vIf.cb);
            vIf.cb.rst <= 1'b0; 
            vIf.cb.recieverInput <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb);
            vIf.cb.recieverInput <= 1'b0;
            #1; // re-fire always_comb logic
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb); // nothing should be shifted in yet
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_start_state_on_start_bit)

    `TEST_TASK(recieverTb, validate_send_state_transition)
        logic[7:0] txLine = 8'b10101010;
        @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            vIf.cb.recieverInput <= 1'b1;
        @(vIf.cb)
            vIf.cb.rst <= 1'b0;
            vIf.cb.recieverInput <= 1'b0;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.cb.recieverInput <= txLine[0];
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.cb.recieverInput <= txLine[1];
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd1, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, 8'b00000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.cb.recieverInput <= txLine[2];
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd2, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, 8'b10000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_send_state_transition)

    `TEST_TASK(recieverTb, validate_stop_state_transition_and_recieve_one_byte)
        logic[7:0] txLine = 8'b10101010;
        logic[15:0] testTx = {txLine, 8'b0};
        @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            vIf.cb.recieverInput <= 1'b1;
        @(vIf.cb)
            vIf.cb.rst <= 1'b0;
            vIf.cb.recieverInput <= 1'b0; // start bit
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < uartFrameSize; iIter++)
        begin
            @(vIf.cb)
                if(iIter == 0)
                begin
                    vIf.cb.recieverInput <= txLine[iIter];
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                else
                begin
                    vIf.cb.recieverInput <= txLine[iIter];
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, iIter, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
                testTx = testTx >> 1;
        end
        @(vIf.cb)
            vIf.cb.recieverInput <= 1; //stop bit
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, txLine}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, txLine}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b1, `REPORT(), "binary");
        @(vIf.cb)
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, txLine}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_stop_state_transition_and_recieve_one_byte)

    `TEST_TASK(recieverTb, validate_reset_on_start_state)
        @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            vIf.recieverInput <= 1'b1;
        @(vIf.cb)
            vIf.rst <= 1'b0;
            vIf.recieverInput <= 1'b0;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.rst <= 1'b1;
            vIf.recieverInput <= 1'b1;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, 8'b00000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, 8'b00000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_reset_on_start_state)

    `TEST_TASK(recieverTb, validate_reset_on_send_state)
        @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            vIf.recieverInput <= 1'b1;
        @(vIf.cb)
            vIf.cb.rst <= 1'b0;
            vIf.recieverInput <= 1'b0;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.recieverInput <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, 8'b00000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd1, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, 8'b10000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.rst <= 1'b1;
            vIf.recieverInput <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd2, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, 8'b11000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, 8'b00000000}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_reset_on_send_state)

    `TEST_TASK(recieverTb, validate_reset_on_stop_bit)
        logic[7:0] txLine = 8'b10101010;
        logic[15:0] testTx = {txLine, 8'b0};
        @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            vIf.cb.recieverInput <= 1'b1;
        @(vIf.cb)
            vIf.cb.rst <= 1'b0;
            vIf.cb.recieverInput <= 1'b0; // start bit
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < uartFrameSize; iIter++)
        begin
            @(vIf.cb)
                if(iIter == 0)
                begin
                    vIf.cb.recieverInput <= txLine[iIter];
                    #1
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                else
                begin
                    vIf.cb.recieverInput <= txLine[iIter];
                    #1
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, iIter, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
                testTx = testTx >> 1;
        end
        @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            vIf.cb.recieverInput <= 1; //stop bit
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, txLine}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_reset_on_stop_bit)

    `TEST_TASK(recieverTb, validate_reset_on_stop_state)
        logic[7:0] txLine = 8'b10101010;
        logic[15:0] testTx = {txLine, 8'b0};
        @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            vIf.cb.recieverInput <= 1'b1;
        @(vIf.cb)
            vIf.cb.rst <= 1'b0;
            vIf.cb.recieverInput <= 1'b0; // start bit
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < uartFrameSize; iIter++)
        begin
            @(vIf.cb)
                if(iIter == 0)
                begin
                    vIf.cb.recieverInput <= txLine[iIter];
                    #1
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                else
                begin
                    vIf.cb.recieverInput <= txLine[iIter];
                    #1
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, iIter, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
                testTx = testTx >> 1;
        end
        @(vIf.cb)
            vIf.cb.recieverInput <= 1; //stop bit
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, txLine}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, txLine}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b1, `REPORT(), "binary");
        @(vIf.cb)
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_reset_on_stop_state)

    `TEST_TASK(recieverTb, validate_send_four_bytes)
        logic[31:0] txLine = {8'b10101011, 8'b00000000, 8'b11111111, 8'b11101110};
        logic[39:0] testTx = {txLine, 8'b0};
        parameter int numBytes = 4;
         @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            vIf.cb.recieverInput <= 1'b1;
        @(vIf.cb)
            vIf.cb.rst <= 1'b0;
            vIf.cb.recieverInput <= 1'b0; // start bit
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        for(int jIter = 0; jIter < numBytes; jIter++)
        begin
            for(int iIter = 0; iIter < uartFrameSize; iIter++)
            begin
                @(vIf.cb)
                    if(iIter == 0)
                    begin
                        vIf.cb.recieverInput <= txLine[0];
                        #1
                        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
                        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                    end
                    else
                    begin
                        vIf.cb.recieverInput <= txLine[0];
                        #1
                        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                    end
                    EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, iIter, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
                testTx = testTx >> 1;
                txLine = txLine >> 1;
            end
            @(vIf.cb)
                vIf.cb.recieverInput <= 1; //stop bit
                #1
                EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
            @(vIf.cb)
                vIf.cb.recieverInput <= 0; //start bit
                #1
                if(numBytes == 3)
                begin
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
                end
                else
                begin
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
                end
                EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b1, `REPORT(), "binary");
        end
    `END_TEST_TASK(recieverTb, validate_send_four_bytes)


    /**
     * behavior on no stop bit is to continue counting up and wait until stop
     * bit. Ignore all incoming bits on the reciever input if no stop bit is
     * recieved. When stop bit is recieved, go to stop state, then idle state. 
     * 
     */
    `TEST_TASK(recieverTb, validate_behavior_no_stop_bit)
        logic[7:0] txLine = 8'b10101010;
        logic[15:0] testTx = {txLine, 8'b0};
        @(vIf.cb)
            vIf.cb.rst <= 1'b1;
            vIf.cb.recieverInput <= 1'b1;
        @(vIf.cb)
            vIf.cb.rst <= 1'b0;
            vIf.cb.recieverInput <= 1'b0; // start bit
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < uartFrameSize; iIter++)
        begin
            @(vIf.cb)
                if(iIter == 0)
                begin
                    vIf.cb.recieverInput <= txLine[iIter];
                    #1
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                else
                begin
                    vIf.cb.recieverInput <= txLine[iIter];
                    #1
                    EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                    EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                end
                EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, iIter, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
                testTx = testTx >> 1;
        end
        @(vIf.cb)
            vIf.cb.recieverInput <= 0; //no stop bit
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.cb.recieverInput <= 0;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.cb.recieverInput <= 1;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
        @(vIf.cb)
            vIf.cb.recieverInput <= 1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd8, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b1, `REPORT(), "binary");
        @(vIf.cb)
            vIf.cb.recieverInput <= 1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({28'b0, dut.recieveCounter}, 32'd0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({24'b0, vIf.cb.byteRecieved}, {24'b0, testTx[7:0]}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
    `END_TEST_TASK(recieverTb, validate_behavior_no_stop_bit)

    initial
    begin
        testFramework::TestManager::runAllTasks();
        $finish;
    end  
endmodule
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
