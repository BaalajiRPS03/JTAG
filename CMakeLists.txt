cmake_minimum_required(VERSION 3.15)

project(JTAG_Stream_Generator NONE)

# Find Icarus Verilog
find_program(IVERILOG_EXECUTABLE iverilog)
find_program(VVP_EXECUTABLE vvp)

if(NOT IVERILOG_EXECUTABLE)
    message(FATAL_ERROR
        "Icarus Verilog was not found. Install it and make sure 'iverilog' is in PATH."
    )
endif()

if(NOT VVP_EXECUTABLE)
    message(FATAL_ERROR
        "Icarus Verilog runtime 'vvp' was not found. Make sure Icarus Verilog is installed correctly."
    )
endif()

set(SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR})

set(SV_SOURCES
    ${SRC_DIR}/jtag_stream_pkg.sv
    ${SRC_DIR}/tb.sv
)

# =========================================================
# COMPILE SYSTEMVERILOG
# =========================================================

add_custom_command(
    OUTPUT ${BUILD_DIR}/jtag_sim.vvp

    COMMAND ${IVERILOG_EXECUTABLE}
            -g2012
            -o ${BUILD_DIR}/jtag_sim.vvp
            -s tb
            ${SV_SOURCES}

    DEPENDS ${SV_SOURCES}

    WORKING_DIRECTORY ${SRC_DIR}

    COMMENT "Compiling SystemVerilog with Icarus Verilog"
)

add_custom_target(build_jtag ALL
    DEPENDS ${BUILD_DIR}/jtag_sim.vvp
)


# =========================================================
# RUN SIMULATION
# =========================================================

add_custom_target(run

    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${SRC_DIR}/JTAG 16bit.txt"
            "${BUILD_DIR}/JTAG 16bit.txt"

    COMMAND ${CMAKE_COMMAND} -E remove -f
            "${BUILD_DIR}/jtag_output.txt"

    COMMAND ${VVP_EXECUTABLE}
            "${BUILD_DIR}/jtag_sim.vvp"

    DEPENDS build_jtag

    WORKING_DIRECTORY ${BUILD_DIR}

    COMMENT "Running JTAG stream generator"
)


# =========================================================
# BUILD + RUN
# =========================================================

add_custom_target(run_jtag
    DEPENDS run
)