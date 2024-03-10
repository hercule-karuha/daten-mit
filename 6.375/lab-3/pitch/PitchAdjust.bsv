
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
module mkPitchAdjust(Integer s, FixedPoint#(isize, fsize) factor, PitchAdjust#(nbins, isize, fsize, psize) ifc)
provisos (Add#(b__, TLog#(TMul#(nbins,2)), isize), Add#(psize, a__, isize));
    
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) inputFIFO  <- mkFIFO();
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) outputFIFO <- mkFIFO();

    Vector#(nbins, Reg#(Phase#(psize))) inphases  <- replicateM(mkReg(0));
    Vector#(nbins, Reg#(Phase#(psize))) outphases <- replicateM(mkReg(0));

    Reg#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) in <- mkRegU();
    Reg#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) out <- mkRegU();

    Reg#(Bit#(TLog#(TMul#(nbins,2)))) i <- mkReg(0);
    Reg#(Bool) inputReady <- mkReg(False);

    rule getInput (i == 0);
        in <= inputFIFO.first;
        out <= replicate(cmplxmp(0, 0));
        inputReady <= True;
        inputFIFO.deq;
    endrule

    rule pitchAdjust (i < fromInteger(valueOf(nbins)) && inputReady);
        Phase#(psize) phase = phaseof(in[i]);
        Phase#(psize) dphase = phase - inphases[i];
        inphases[i] <= phase;

        Int#(isize) iInt = unpack(extend(i));
        Int#(isize) bin = fxptGetInt(fromInt(iInt) * factor);
        Int#(isize) nbin = fxptGetInt(fromInt(iInt + 1) * factor);

        FixedPoint#(isize, fsize) dphaseFxp = fromInt(dphase);

        if (bin < fromInteger(valueOf(nbins)) && bin >= 0 && nbin != bin) begin
            Phase#(psize) shifted = truncate(fxptGetInt(dphaseFxp * factor));
            outphases[bin] <= outphases[bin] + shifted;
            out[bin] <= cmplxmp(in[i].magnitude, outphases[bin] + shifted);
            $display("write bin: ",fshow(bin)," nbin: ",fshow(nbin)," shifted: ",fshow(shifted));
        end
        i <= i + 1;
    endrule

    rule outputResult (i == fromInteger(valueOf(nbins)));
        outputFIFO.enq(out);
        i <= 0;
        inputReady <= False;
    endrule

    interface Put request;
        method Action put(Vector#(nbins, ComplexMP#(isize, fsize, psize)) x);
            inputFIFO.enq(x);
        endmethod
    endinterface

    interface Get response = toGet(outputFIFO);
endmodule
