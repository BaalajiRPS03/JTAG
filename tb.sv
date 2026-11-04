// ============================================================
// tb.sv
// ============================================================

module tb;

    `include "jtag_stream_pkg.sv"

    integer read_ok;

    initial begin

        // Read instructions
        read_instructions_from_file(
            "JTAG 16bit.txt",
            read_ok
        );


        // Generate output
        if (read_ok == 1) begin

            generate_jtag_stream;

        end
        else begin

            $display("JTAG generation skipped.");

        end


        $display("");
        $display("Simulation completed.");

        $finish;

    end

endmodule