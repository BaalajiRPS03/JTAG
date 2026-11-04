// ============================================================
// jtag_stream_pkg.sv
// JTAG Stream Generator
// ============================================================

parameter WORD_WIDTH  = 16;
parameter WORDS_BURST = 32;

typedef logic [WORD_WIDTH-1:0] instruction_t;

instruction_t instructions [0:100000];
integer instruction_count;


// ============================================================
// READ INPUT FILE
// ============================================================

task read_instructions_from_file(
    input string filename,
    output integer success
);

    integer fd;
    integer status;
    integer i;
    reg [WORD_WIDTH-1:0] instruction;

    string token;              // ADDED
    integer token_length;      // ADDED
    integer validation_error;  // ADDED
    integer token_number;      // ADDED

    begin

        success = 0;
        instruction_count = 0;

        validation_error = 0;  // ADDED
        token_number = 0;      // ADDED

        fd = $fopen(filename, "r");

        if (fd == 0) begin

            $display("");
            $display("ERROR: Cannot open input file: %s", filename);
            $display("");

        end
        else begin

            $display("Reading input file: %s", filename);
            $display("");

            while (!$feof(fd)) begin

                // ------------------------------------------------
                // ADDED:
                // Read input as a string first so we can check
                // whether it contains exactly 16 bits.
                // ------------------------------------------------

                status = $fscanf(fd, "%s", token);  // ADDED

                if (status == 1) begin  // ADDED

                    // ------------------------------------------------
                    // ADDED:
                    // Count EVERY input token, including invalid ones.
                    // ------------------------------------------------

                    token_number = token_number + 1;  // ADDED

                    token_length = token.len();  // ADDED

                    // ------------------------------------------------
                    // ADDED:
                    // Check exactly 16 bits
                    // ------------------------------------------------

                    if (token_length != WORD_WIDTH) begin  // ADDED

                        $display(
                            "ERROR: Input token %0d has %0d bits. Expected exactly %0d bits: %s",
                            token_number,
                            token_length,
                            WORD_WIDTH,
                            token
                        );  // ADDED

                        validation_error = 1;  // ADDED

                    end
                    else begin  // ADDED

                        // ------------------------------------------------
                        // Existing conversion logic
                        // ------------------------------------------------

                        status = $sscanf(token, "%b", instruction);  // ADDED

                        if (status == 1) begin  // ADDED

                            instructions[instruction_count] = instruction;

                            instruction_count = instruction_count + 1;

                        end
                        else begin  // ADDED

                            $display(
                                "ERROR: Invalid binary value at input %0d: %s",
                                token_number,
                                token
                            );  // ADDED

                            validation_error = 1;  // ADDED

                        end

                    end  // ADDED

                end  // ADDED

            end

            $fclose(fd);

            // ------------------------------------------------
            // ADDED:
            // If any token failed validation, don't continue
            // with JTAG generation.
            // ------------------------------------------------

            if (validation_error == 1) begin  // ADDED

                instruction_count = 0;  // ADDED
                success = 0;            // ADDED

                $display("");
                $display("ERROR: Input validation failed.");
                $display("JTAG stream generation skipped.");
                $display("");

            end
            else if (instruction_count == 0) begin

                $display("ERROR: Input file contains no instructions.");

            end
            else begin

                success = 1;

                $display("Total instructions read = %0d",
                         instruction_count);

                $display("");

            end

        end

    end

endtask


// ============================================================
// GENERATE JTAG STREAM
// ============================================================

task generate_jtag_stream;

    integer output_fd;

    integer total_instructions;
    integer total_bursts;

    integer burst;
    integer word;

    integer instruction_index;

    integer actual_words;
    integer padded_words;

    integer expected_output_words;
    integer generated_output_words;

    begin

        if (instruction_count == 0) begin

            $display("");
            $display("ERROR: No instructions available.");
            $display("");

        end
        else begin

            total_instructions = instruction_count;

            // Calculate number of bursts
            total_bursts =
                (total_instructions + WORDS_BURST - 1)
                / WORDS_BURST;

            expected_output_words =
                total_bursts * WORDS_BURST;


            // ------------------------------------------------
            // Open output file
            // ------------------------------------------------

            output_fd = $fopen("jtag_output.txt", "w");

            if (output_fd == 0) begin

                $display("");
                $display("ERROR: Cannot create jtag_output.txt");
                $display("");

            end
            else begin

                instruction_index = 0;

                actual_words = 0;
                padded_words = 0;


                // ====================================================
                // BURST LOOP
                // ====================================================

                for (burst = 0;
                     burst < total_bursts;
                     burst = burst + 1) begin


                    // ------------------------------------------------
                    // Burst header
                    // ------------------------------------------------

                    $fdisplay(output_fd,
                              "BURST %0d",
                              burst + 1);


                    // ====================================================
                    // 32 WORDS PER BURST
                    // ====================================================

                    for (word = 0;
                         word < WORDS_BURST;
                         word = word + 1) begin


                        // ------------------------------------------------
                        // Actual instruction
                        // ------------------------------------------------

                        if (instruction_index < total_instructions) begin

                            $fdisplay(output_fd,
                                      "Word %02d : %016b",
                                      word + 1,
                                      instructions[instruction_index]);

                            instruction_index = instruction_index + 1;

                            actual_words = actual_words + 1;

                        end


                        // ------------------------------------------------
                        // Zero padding
                        // ------------------------------------------------

                        else begin

                            $fdisplay(output_fd,
                                      "Word %02d : 0000000000000000",
                                      word + 1);

                            padded_words = padded_words + 1;

                        end

                    end


                    // Empty line after every burst

                    $fdisplay(output_fd, "");

                end


                // ------------------------------------------------
                // Close output file
                // ------------------------------------------------

                $fclose(output_fd);


                generated_output_words =
                    actual_words + padded_words;


                // ====================================================
                // SUMMARY
                // ====================================================

                $display("");
                $display("============================================");
                $display("JTAG STREAM GENERATION COMPLETED");
                $display("============================================");

                $display("Actual instruction words = %0d",
                         actual_words);

                $display("Zero-padded words        = %0d",
                         padded_words);

                $display("Total output words       = %0d",
                         generated_output_words);

                $display("Expected output words    = %0d",
                         expected_output_words);


                // ------------------------------------------------
                // Verification
                // ------------------------------------------------

                if ((actual_words == total_instructions) &&
                    (generated_output_words ==
                     expected_output_words)) begin

                    $display("Output verification : PASSED");

                end
                else begin

                    $display("Output verification : FAILED");

                end


                $display("");
                $display("Output file: jtag_output.txt");
                $display("");

            end

        end

    end

endtask