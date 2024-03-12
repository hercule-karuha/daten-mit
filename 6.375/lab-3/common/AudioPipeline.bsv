
import ClientServer::*;
import GetPut::*;

import FixedPoint::*;
import AudioProcessorTypes::*;
import Chunker::*;
import FFT::*;
import FIRFilter::*;
import Splitter::*;
import FilterCoefficients::*;
import FromMP::*;
import ToMP::*;
import PitchAdjust::*;

module mkAudioPipeline(AudioProcessor);

    AudioProcessor fir <- mkFIRFilter(c);
    Chunker#(FFT_POINTS, ComplexSample) chunker <- mkChunker();
    FFT#(FFT_POINTS, FixedPoint#(16, 16)) fft <- mkFFT();
    ToMP#(FFT_POINTS, 16, 16, PSIZE) tomp <- mkToMP();
    PitchAdjust#(FFT_POINTS, 16, 16, PSIZE) adjust <- mkPitchAdjust(2, 2.0);
    FromMP#(FFT_POINTS, 16, 16, PSIZE) frommp <- mkFromMP();
    FFT#(FFT_POINTS, FixedPoint#(16, 16)) ifft <- mkIFFT();
    Splitter#(FFT_POINTS, ComplexSample) splitter <- mkSplitter();

    rule fir_to_chunker (True);
        let x <- fir.getSampleOutput();
        chunker.request.put(tocmplx(x));
    endrule

    rule chunker_to_fft (True);
        let x <- chunker.response.get();
        fft.request.put(x);
    endrule

    rule fft_to_tomp (True);
        let x <- fft.response.get();
        tomp.request.put(x);
    endrule

    rule tomp_to_adjust (True);
        let x <- tomp.response.get();
        adjust.request.put(x);
    endrule

    rule adjust_to_frommp (True);
        let x <- adjust.response.get();
        frommp.request.put(x);
    endrule

    rule frommp_to_ifft (True);
        let x <- frommp.response.get();
        ifft.request.put(x);
    endrule

    rule ifft_to_splitter (True);
        let x <- ifft.response.get();
        splitter.request.put(x);
    endrule
    
    method Action putSampleInput(Sample x);
        fir.putSampleInput(x);
    endmethod

    method ActionValue#(Sample) getSampleOutput();
        let x <- splitter.response.get();
        return frcmplx(x);
    endmethod

endmodule

