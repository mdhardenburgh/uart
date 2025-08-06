#include "verilated.h"
#include "transmitterTb.h"
int main(int argc, char** argv) 
{
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    transmitterTb* top = new transmitterTb{contextp};

    // run until $finish or $fatal
    while (!contextp->gotFinish()) {
        top->eval();          // evaluate pending events at the current time
        contextp->timeInc(1);      // advance simulation time by 1 time-unit
    }
    delete top;
    delete contextp;
    return 0;
}