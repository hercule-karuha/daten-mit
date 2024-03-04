import FIFO::*;
import Vector::*;
import FixedPoint::*;
import AudioProcessorTypes::*;
import FilterCoefficients::*;
import Multiplier::*;

module mkFIRFilter (AudioProcessor);

    FIFO#(Sample) infifo <- mkFIFO();
    FIFO#(Sample) outfifo <- mkFIFO();

    Vector#(8, Reg#(Sample)) r <- replicateM(mkReg(0));

    Vector#(9, Multiplier) multipliers <- replicateM(mkMultiplier());

    rule putMulOperand (True);
        Sample sample = infifo.first();
        infifo.deq();

        r[0] <= sample;
        for (Integer i = 0; i < 7; i = i+1) begin
            r[i+1] <= r[i];
        end
        
        multipliers[0].putOperands(c[0], sample);
        for(Integer i = 0; i < 8 ;i = i+1) begin
            multipliers[i+1].putOperands(c[i+1], r[i]);
        end
    endrule

    rule getMulResult (True);
        let x0 <- multipliers[0].getResult();
        let x1 <- multipliers[1].getResult();
        let x2 <- multipliers[2].getResult();
        let x3 <- multipliers[3].getResult();
        let x4 <- multipliers[4].getResult();
        let x5 <- multipliers[5].getResult();
        let x6 <- multipliers[6].getResult();
        let x7 <- multipliers[7].getResult();
        let x8 <- multipliers[8].getResult();

        FixedPoint#(16, 16) accumulate = x0 + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8;
        outfifo.enq(fxptGetInt(accumulate));
    endrule

    method Action putSampleInput(Sample in);
        infifo.enq(in);
    endmethod

    method ActionValue#(Sample) getSampleOutput();
        outfifo.deq();
        return outfifo.first();
    endmethod

endmodule