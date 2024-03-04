import FIFO::*;
import Vector::*;
import FixedPoint::*;
import AudioProcessorTypes::*;
import FilterCoefficients::*;

module mkFIRFilter (AudioProcessor);

    FIFO#(Sample) infifo <- mkFIFO();
    FIFO#(Sample) outfifo <- mkFIFO();

    Vector#(8, Reg#(Sample)) r <- replicateM(mkReg(0));

    rule process (True);
        Sample sample = infifo.first();
        infifo.deq();
        r[0] <= sample;
        
        for (Integer i = 0; i < 7; i = i+1) begin
            r[i+1] <= r[i];
        end

        FixedPoint#(16,16) accumulate = c[0] * fromInt(sample)
        + c[1] * fromInt(r[0])
        + c[2] * fromInt(r[1])
        + c[3] * fromInt(r[2])
        + c[4] * fromInt(r[3])
        + c[5] * fromInt(r[4])
        + c[6] * fromInt(r[5])
        + c[7] * fromInt(r[6])
        + c[8] * fromInt(r[7]);
    
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