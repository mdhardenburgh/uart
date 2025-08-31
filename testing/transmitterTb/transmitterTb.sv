`include "uartUtil.sv"
/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSEDSIGNAL */
interface txIf;
    logic clk, rst;
    logic send; 
    logic[7:0] byteToLoad;
    logic transmitOutput, done;

    /* verilator lint_off UNDRIVEN */
    clocking cb @(posedge clk);
        // Read DUT outputs at the edge; drive TB outputs just after the edge
        default input #0 output #0;
        output rst, send, byteToLoad; // TB drives these (DUT inputs)
        input  transmitOutput, done;  // TB samples these (DUT outputs)
    endclocking
    /* verilator lint_on UNDRIVEN */
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
        @(vIf.cb);
            // reset all inputs, clear state from prev test
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= 8'h00;
        @(vIf.cb);
            vIf.cb.rst <= 1'b0;
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        @(vIf.cb);
            vIf.cb.rst <= 1'b1;
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        @(vIf.cb);
            vIf.cb.rst <= 1'b0;
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, "", "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.done}, 32'b0, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, vaildate_output_on_reset)

    `TEST_TASK(transmitterTb, validate_byte_loaded_on_send)
        logic[7:0] byteToTransmit = 8'h00;
        @(vIf.cb);
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= byteToTransmit;
        @(vIf.cb);
            byteToTransmit = 8'hFF;
            vIf.cb.rst <= 1'b0;
            vIf.cb.send <= 1'b1;
            vIf.cb.byteToLoad <= byteToTransmit;
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(vIf.cb); // latches rst = 0, send = 1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, `REPORT(), "binary");
        // loadedByte doesnt latch until after the clock cycle
        @(vIf.cb);
            EXPECT_EQ_LOGIC({24'b0, dut.loadedByte}, 32'h000000FF, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_byte_loaded_on_send)

    `TEST_TASK(transmitterTb, validate_send_byte)
        logic[7:0] byteToTransmit = 8'h00;
        @(vIf.cb);
            // reset all inputs, clear state from prev test
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= byteToTransmit;
        @(vIf.cb);
            byteToTransmit = 8'b10100110;
            vIf.cb.rst <= 1'b0; // still idle state until after clock edge
            vIf.cb.byteToLoad <= byteToTransmit;
            vIf.cb.send <= 1'b1; // combinational logic takes a prop delay
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(vIf.cb);
            vIf.cb.send <= 1'b0;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(vIf.cb); // send 0 to 6
                EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(vIf.cb); // send 7
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[7]}, `REPORT(), "binary");
        @(vIf.cb); // stop
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
        @(vIf.cb); // back to IDLE
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_send_byte)

    `TEST_TASK(transmitterTb, validate_second_start_after_first_byte)
        logic[7:0] byteToTransmit = 8'h00;
        @(vIf.cb);
            // reset all inputs, clear state from prev test
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= 8'h00;
        @(vIf.cb);
            byteToTransmit = 8'b11100100;
            vIf.cb.rst <= 1'b0;
            vIf.cb.send <= 1'b1;
            vIf.cb.byteToLoad <= byteToTransmit; // combinational logic takes a prop delay, check state next cycle
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND},`REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(vIf.cb); // send 0 to 6
                EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(vIf.cb); // send 7
            byteToTransmit = 8'b11100101;
            vIf.cb.byteToLoad <= byteToTransmit;
            vIf.cb.send <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, vIf.byteToLoad[7]}, `REPORT(), "binary");
        @(vIf.cb); // stop
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
        @(vIf.cb); // back to START
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b0}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({29'b0, dut.sendCounter}, {32'b0}, `REPORT(), "binary");
        @(vIf.cb); // back to SEND
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[0]}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({29'b0, dut.sendCounter}, {32'b0}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_second_start_after_first_byte)

    `TEST_TASK(transmitterTb, validate_send_double)
        logic[7:0] byteToTransmit = 8'h00;
        @(vIf.cb);
            // reset all inputs, clear state from prev test
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= byteToTransmit;
        @(vIf.cb);
            byteToTransmit = 8'b11100100;
            vIf.cb.rst <= 1'b0;
            vIf.cb.send <= 1'b1;
            vIf.cb.byteToLoad <= byteToTransmit; // combinational logic takes a prop delay, check state next cycle
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND},`REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(vIf.cb); // send 0 to 6
                EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(vIf.cb); // send 7
            byteToTransmit = 8'b11100101;
            vIf.cb.byteToLoad <= byteToTransmit;
            vIf.cb.send <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[7]}, `REPORT(), "binary");
        @(vIf.cb); // stop
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
        @(vIf.cb); // back to START
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b0}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({29'b0, dut.sendCounter}, {32'b0}, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(vIf.cb); // send 0 to 6
                EXPECT_EQ_LOGIC({29'b0, dut.sendCounter}, iIter, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(vIf.cb); // send 7
            vIf.cb.send <= 1'b0;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[7]}, `REPORT(), "binary");
        @(vIf.cb); // stop
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
        @(vIf.cb); // back to IDLE
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_send_double)

    `TEST_TASK(transmitterTb, validate_reset_on_start_state)
        logic[7:0] byteToTransmit = 8'h00;
        @(vIf.cb);
            // reset all inputs, clear state from prev test
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= byteToTransmit;
        @(vIf.cb);
            byteToTransmit = 8'b11100100;
            vIf.cb.rst <= 1'b0;
            vIf.cb.send <= 1'b1;
            vIf.cb.byteToLoad <= byteToTransmit;
            #1 //wait one time delay
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(vIf.cb);
            vIf.cb.rst <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b0, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b1, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_on_start_state)

    `TEST_TASK(transmitterTb, validate_reset_on_send_state)
        logic[7:0] byteToTransmit = 8'h00;
        @(vIf.cb);
            // reset all inputs, clear state from prev test
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= byteToTransmit;
        @(vIf.cb);
            byteToTransmit = 8'b10101100;
            vIf.cb.rst <= 1'b0;
            vIf.cb.send <= 1'b1;
            vIf.cb.byteToLoad <= byteToTransmit;
            #1 //wait one time delay
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b0, `REPORT(), "binary");
        @(vIf.cb);
            vIf.cb.rst <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, {31'b0, byteToTransmit[0]}, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.transmitOutput}, 32'b1, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_on_send_state)

    `TEST_TASK(transmitterTb, validate_reset_on_last_send_state)
        logic[7:0] byteToTransmit = 8'h00;
        @(vIf.cb);
            // reset all inputs, clear state from prev test
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= byteToTransmit;
        @(vIf.cb);
            byteToTransmit = 8'b11100111;
            vIf.cb.rst <= 1'b0; // still idle state until after clock edge
            vIf.cb.byteToLoad <= byteToTransmit;
            vIf.cb.send <= 1'b1; // combinational logic takes a prop delay
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(vIf.cb); // send 0 to 6
                EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(vIf.cb); // send 7
            vIf.cb.rst <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[7]}, `REPORT(), "binary");
        @(vIf.cb); // stop
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_on_last_send_state)

    `TEST_TASK(transmitterTb, validate_reset_on_stop_state)
        logic[7:0] byteToTransmit = 8'h00;
        @(vIf.cb);
            // reset all inputs, clear state from prev test
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= byteToTransmit;
        @(vIf.cb);
            byteToTransmit = 8'b10110110;
            vIf.cb.rst <= 1'b0; // still idle state until after clock edge
            vIf.cb.byteToLoad <= byteToTransmit;
            vIf.cb.send <= 1'b1; // combinational logic takes a prop delay
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b0, `REPORT(), "binary");
        for(int iIter = 0; iIter < 7; iIter++)
        begin
            @(vIf.cb); // send 0 to 6
                EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
                EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[iIter]}, $sformatf("%s: %0d, iIter: %0d", `__FILE__, `__LINE__, iIter), "binary");
        end
        @(vIf.cb); // send 7
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[7]}, `REPORT(), "binary");
        @(vIf.cb); // stop
            vIf.rst <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::STOP}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
        @(vIf.cb)
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_on_stop_state)

    `TEST_TASK(transmitterTb, validate_reset_in_middle_of_send)
        logic[7:0] byteToTransmit = 8'h00;
        @(vIf.cb);
            // reset all inputs, clear state from prev test
            vIf.cb.rst <= 1'b1;
            vIf.cb.send <= 1'b0;
            vIf.cb.byteToLoad <= byteToTransmit;
        @(vIf.cb);
            byteToTransmit = 8'b10100110;
            vIf.cb.rst <= 1'b0; // still idle state until after clock edge
            vIf.cb.byteToLoad <= byteToTransmit;
            vIf.cb.send <= 1'b1; // combinational logic takes a prop delay
            #1
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, 32'b0, `REPORT(), "binary");
        @(vIf.cb); // send 0 
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[0]}, `REPORT(), "binary");
        @(vIf.cb); // send 1
            vIf.cb.rst <= 1'b1;
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::SEND}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {31'b0, byteToTransmit[1]}, `REPORT(), "binary");
        @(vIf.cb);
            EXPECT_EQ_LOGIC({30'b0, dut.stateCounter}, {30'b0, uartUtil::IDLE}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({30'b0, dut.nextState}, {30'b0, uartUtil::START}, `REPORT(), "binary");
            EXPECT_EQ_LOGIC({31'b0, vIf.cb.transmitOutput}, {32'b1}, `REPORT(), "binary");
    `END_TEST_TASK(transmitterTb, validate_reset_in_middle_of_send)
    
    initial
    begin
        testFramework::TestManager::runAllTasks();
        $finish;
    end  
endmodule
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
