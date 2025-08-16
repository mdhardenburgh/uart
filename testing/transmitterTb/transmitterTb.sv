`include "uartUtil.sv"
/* verilator lint_off DECLFILENAME */
interface txIf;
    logic clk, rst;
    logic send; 
    logic[7:0] byteToLoad;
    logic transmitOutput, done;
endinterface
module transmitterTb;
    // "virtual interface" to get verilator to play nice with the test framework
    txIf vIf();
    import testFramework::*;

    transmitter dut
    (
        .clk(vIf.clk),
        .rst(vIf.rst),
        .send(vIf.send),
        .byteToLoad(vIf.byteToLoad),
        .transmitOutput(vIf.transmitOutput),
        .done(vIf.done)
    );

    initial
    begin
        vIf.clk = 1'b0;
        forever #20 vIf.clk = ~vIf.clk;
    end

    `TEST_TASK(transmitterTb, vaildate_output_on_reset)
        @(posedge vIf.clk);
        // reset all inputs, clear state from prev test
        vIf.rst = 1'b1;
        vIf.send = 1'b0;
        vIf.byteToLoad = 8'h00;
        @(posedge vIf.clk);
        vIf.rst = 1'b0;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        @(posedge vIf.clk);
        vIf.rst = 1'b1;
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        @(posedge vIf.clk);
        vIf.rst = 1'b0;
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, "", "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.done}, 32'b0, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, vaildate_output_on_reset)

    `TEST_TASK(transmitterTb, validate_byte_loaded_on_send)
        @(posedge vIf.clk);
        vIf.rst = 1'b1;
        vIf.send = 1'b0;
        vIf.byteToLoad = 8'h00;
        @(posedge vIf.clk);
        vIf.rst = 1'b0;
        vIf.send = 1'b1;
        vIf.byteToLoad = 8'hFF;
        #1
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(posedge vIf.clk); // latches rst = 0, send = 1
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        // loadedByte doesnt latch until after the clock cycle
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({24'b0, dut.loadedByte}, 32'h000000FF, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_byte_loaded_on_send)

    `TEST_TASK(transmitterTb, validate_send_byte)
        @(posedge vIf.clk);
        // reset all inputs, clear state from prev test
        vIf.rst = 1'b1;
        vIf.send = 1'b0;
        vIf.byteToLoad = 8'h00;
        @(posedge vIf.clk);
        vIf.rst = 1'b0; // still idle state until after clock edge
        vIf.byteToLoad = 8'b10100110;
        vIf.send = 1'b1; // combinational logic takes a prop delay
        #1
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(posedge vIf.clk);
        vIf.send = 1'b0;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(posedge vIf.clk); // send 0 to 6
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(posedge vIf.clk); // send 7
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[7]}, `REPORT(), "binary");
        @(posedge vIf.clk); // stop
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b1}, `REPORT(), "binary");
        @(posedge vIf.clk); // back to IDLE
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_send_byte)

    `TEST_TASK(transmitterTb, validate_send_double)
        @(posedge vIf.clk);
        // reset all inputs, clear state from prev test
        vIf.rst = 1'b1;
        vIf.send = 1'b0;
        vIf.byteToLoad = 8'h00;
        @(posedge vIf.clk);
        vIf.rst = 1'b0;
        vIf.send = 1'b1;
        vIf.byteToLoad = 8'b11100100; // combinational logic takes a prop delay, check state next cycle
        #1
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START},`REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk); 
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(posedge vIf.clk); // send 0 to 6
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(posedge vIf.clk); // send 7
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[7]}, `REPORT(), "binary");
        @(posedge vIf.clk); // stop
        vIf.byteToLoad = 8'b11100100;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b1}, `REPORT(), "binary");
        @(posedge vIf.clk); // back to START
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b0}, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(posedge vIf.clk); // send 0 to 6
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(posedge vIf.clk); // send 7
        vIf.send = 1'b0;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[7]}, `REPORT(), "binary");
        @(posedge vIf.clk); // stop
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b1}, `REPORT(), "binary");
        @(posedge vIf.clk); // back to IDLE
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_send_double)

    `TEST_TASK(transmitterTb, validate_reset_on_start_state)
        @(posedge vIf.clk);
        // reset all inputs, clear state from prev test
        vIf.rst = 1'b1;
        vIf.send = 1'b0;
        vIf.byteToLoad = 8'h00;
        @(posedge vIf.clk);
        vIf.rst = 1'b0;
        vIf.send = 1'b1;
        vIf.byteToLoad = 8'b11100100;
        #1 //wait one time delay
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk);
        vIf.rst = 1'b1;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_on_start_state)

    `TEST_TASK(transmitterTb, validate_reset_on_send_state)
        @(posedge vIf.clk);
        // reset all inputs, clear state from prev test
        vIf.rst = 1'b1;
        vIf.send = 1'b0;
        vIf.byteToLoad = 8'h00;
        @(posedge vIf.clk);
        vIf.rst = 1'b0;
        vIf.send = 1'b1;
        vIf.byteToLoad = 8'b11100100;
        #1 //wait one time delay
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk);
        vIf.rst = 1'b1;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_on_send_state)

    `TEST_TASK(transmitterTb, validate_reset_on_last_send_state)
        @(posedge vIf.clk);
        // reset all inputs, clear state from prev test
        vIf.rst = 1'b1;
        vIf.send = 1'b0;
        vIf.byteToLoad = 8'h00;
        @(posedge vIf.clk);
        vIf.rst = 1'b0; // still idle state until after clock edge
        vIf.byteToLoad = 8'b10100110;
        vIf.send = 1'b1; // combinational logic takes a prop delay
        #1
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(posedge vIf.clk);
        vIf.send = 1'b0;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(posedge vIf.clk); // send 0 to 6
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(posedge vIf.clk); // send 7
        vIf.rst = 1'b1;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[7]}, `REPORT(), "binary");
        @(posedge vIf.clk); // stop
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_on_last_send_state)

    `TEST_TASK(transmitterTb, validate_reset_on_stop_state)
        @(posedge vIf.clk);
        // reset all inputs, clear state from prev test
        vIf.rst = 1'b1;
        vIf.send = 1'b0;
        vIf.byteToLoad = 8'h00;
        @(posedge vIf.clk);
        vIf.rst = 1'b0; // still idle state until after clock edge
        vIf.byteToLoad = 8'b10100110;
        vIf.send = 1'b1; // combinational logic takes a prop delay
        #1
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(posedge vIf.clk); // send 0 to 6
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(posedge vIf.clk); // send 7
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[7]}, `REPORT(), "binary");
        @(posedge vIf.clk); // stop
        vIf.rst = 1'b1;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b1}, `REPORT(), "binary");
        @(posedge vIf.clk)
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_on_stop_state)

    `TEST_TASK(transmitterTb, validate_reset_in_middle_of_send)
        @(posedge vIf.clk);
        // reset all inputs, clear state from prev test
        vIf.rst = 1'b1;
        vIf.send = 1'b0;
        vIf.byteToLoad = 8'h00;
        @(posedge vIf.clk);
        vIf.rst = 1'b0; // still idle state until after clock edge
        vIf.byteToLoad = 8'b10100110;
        vIf.send = 1'b1; // combinational logic takes a prop delay
        #1
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        @(posedge vIf.clk); // send 0 
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[0]}, `REPORT(), "binary");
        @(posedge vIf.clk); // send 1
        vIf.rst = 1'b1;
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, vIf.byteToLoad[1]}, `REPORT(), "binary");
        @(posedge vIf.clk);
        EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_in_middle_of_send)

    initial
    begin
        testFramework::TestManager::runAllTasks();
        $finish;
    end  
endmodule
/* verilator lint_on DECLFILENAME */
