
import ClientServer::*;
import FIFO::*;
import GetPut::*;

import FixedPoint::*;
import Vector::*;

import ComplexMP::*;


typedef Server#(
    Vector#(nbins, ComplexMP#(isize, fsize, psize)),
    Vector#(nbins, ComplexMP#(isize, fsize, psize))
) PitchAdjust#(numeric type nbins, numeric type isize, numeric type fsize, numeric type psize);


// s - the amount each window is shifted from the previous window.
//
// factor - the amount to adjust the pitch.
//  1.0 makes no change. 2.0 goes up an octave, 0.5 goes down an octave, etc...
module mkPitchAdjust(Integer s, FixedPoint#(isize, fsize) factor, PitchAdjust#(nbins, isize, fsize, psize) ifc);
    
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) inputFIFO  <- mkFIFO();
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) outputFIFO <- mkFIFO();

    Vector#(nbins, Reg#(Phase#(psize))) inphases  <- replicateM(mkReg(0));
    Vector#(nbins, Reg#(Phase#(psize))) outphases <- replicateM(mkReg(0));

    Reg#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) out <- mkRegU();

    rule pitchAdjust;
        let inCmps =  inputFIFO.first;
        inputFIFO.deq;
        for(Integer i = 0; i < valueOf(nbins); i++){
            Phase#(psize) phase = phaseof(inCmps[i]);
            Phase#(psize) dphase = phase - inphases[i];
            inphases[i] <= phase;

            FixedPoint#(isize, fsize) iPoint = fromInt(fromInteger(i));
            Int#(TLog#(nbins)) bin = fxptGetInt(i * factor);

            if (bin < fromInteger(valueOf(nbins))) begin
            Phase#(psize) shifted = fxptGetInt(fromInt(dphase) * factor);
            outphases[bin] <= outphases[bin] + shifted;
            out[bin] <= cmplxmp(inCmps[i].magnitude, outphases[bin] + shifted);
            end
        }
        outputFIFO.enq(out);
    endrule

    interface Put request;
        method Action put(Vector#(nbins, ComplexMP#(isize, fsize, psize)) x);
            inputFIFO.enq(x);
        endmethod
    endinterface

    interface Get response = toGet(outputFIFO);
endmodule
