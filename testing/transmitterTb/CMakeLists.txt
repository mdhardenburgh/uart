# vivado flow:
# export VIVADO=1
# cmake -S . -B build
# verilator flow:
# export VERILATE=1
# cmake -S . -B build
# cmake --build build --target transmitterTb

cmake_minimum_required(VERSION 3.23.1)
project(transmitterTb VERSION 1.0)
cmake_policy(SET CMP0074 NEW)

include(ProcessorCount)
ProcessorCount(NCPU)

# Options (use -Dverilate=ON or -Dvivado=ON)
#option(verilate "Build with Verilator" OFF)
#option(vivado   "Run Vivado batch flow" OFF)

# Make them mutually exclusive
if($ENV{VERILATE} AND $ENV{VIVADO})
    message(FATAL_ERROR "Choose exactly one: export VIVADO=1 or export VERILATE=1 (not both).")
endif()

# Tooling discovery
if(verilate)
    find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
    if(NOT verilator_FOUND)
        message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
    endif()
else()
    find_program(VIVADO_EXECUTABLE NAMES vivado 
    HINTS $ENV{XILINX_VIVADO}/bin
    /tools/Xilinx/2025.1/Vivado/bin
    )
    if(NOT VIVADO_EXECUTABLE)
        message(FATAL_ERROR "Vivado not found, if you are using vivado, set the enviroment variable XILINX_VIVADO to the bin directory")
    else()
        message(NOTICE "Vivado located at ${VIVADO_EXECUTABLE}")
    endif()
    #set(VIVADO_TCL transmitterTb.tcl)
    set(VIVADO_TCL "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.tcl" CACHE FILEPATH "Vivado TCL script")
endif()
# GIT_TAG        18ab4a2015df7f766caf52ae4720080de8ecd3cc # v1.0.00-pre-release
#GIT_TAG        be881fdc4252a2d3e372e193f1a4a520c680be79
include(FetchContent)
FetchContent_Declare(
    svTest
    # Specify the commit you depend on and update it regularly.
    GIT_REPOSITORY https://github.com/mdhardenburgh/svTest.git
    GIT_TAG        be881fdc4252a2d3e372e193f1a4a520c680be79 # v1.0.00-pre-release
)
FetchContent_MakeAvailable(svTest)
# fetch interface library file lists:
get_target_property(tbTestFiles src INTERFACE_SOURCES)
get_target_property(svTestFiles svTest INTERFACE_SOURCES)
get_target_property(INCLD_DIRS  src INTERFACE_INCLUDE_DIRECTORIES)

# Put them (plus tb.sv itself) into one variable:
separate_arguments(tbTestFiles)
separate_arguments(svTestFiles)
set(SOURCE_LIST
    ${svTestFiles}
    ${tbTestFiles}
    ${CMAKE_CURRENT_LIST_DIR}/transmitterTb.sv
)
if($ENV{VIVADO})
    string(REPLACE ";" "\n" SOURCE_LIST "${SOURCE_LIST}")
    set(WORKING_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    set(SOURCE_LIST_FILE "${CMAKE_CURRENT_BINARY_DIR}/sourceList.txt")
    message(NOTICE "Source list: ${SOURCE_LIST}")
    message(NOTICE "Writing source list file to ${SOURCE_LIST_FILE}")
    file(WRITE ${SOURCE_LIST_FILE} "${SOURCE_LIST}")
    message(NOTICE "Copying ${PROJECT_NAME}.tcl to ${CMAKE_CURRENT_BINARY_DIR}")
    file(COPY "${PROJECT_NAME}.tcl" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
elseif($ENV{VERILATE})
    message(NOTICE "Source list: ${SOURCE_LIST}")
endif()

# Create a new executable target that will contain all your sources
if($ENV{VERILATE})
    add_executable(${PROJECT_NAME} transmitterTb.cpp)
    target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)
    # -Wno-{warning-code}
    #set(ARGS -Wno-LATCH -Wno-UNOPTFLAT -Wno-INITIALDLY -Wno-MULTIDRIVEN -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --assert --timing)
    set(ARGS -Wno-DECLFILENAME -Wall -Wpedantic --assert --timing)
    target_link_libraries(${PROJECT_NAME} PRIVATE src svTest)

    # -j$(nproc)
    # Add the Verilated circuit to the target
    verilate(${PROJECT_NAME}
        SOURCES ${SOURCE_LIST}
        PREFIX ${PROJECT_NAME}
        TOP_MODULE ${PROJECT_NAME}
        THREADS ${NCPU}
        VERILATOR_ARGS ${ARGS}
        INCLUDE_DIRS ${INCLD_DIRS}
    )
else()
    add_custom_target(transmitterTb
    COMMAND "${VIVADO_EXECUTABLE}" -mode batch -source "${VIVADO_TCL}" -journal "${CMAKE_CURRENT_BINARY_DIR}/vivado.jou" -log "${CMAKE_CURRENT_BINARY_DIR}/vivado.log"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Running Vivado (batch) with ${VIVADO_TCL}"
    VERBATIM
)

endif()