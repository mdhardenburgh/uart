# cmake -S . -B build
# cmake --build build --target recieverTb

cmake_minimum_required(VERSION 3.23.1)
project(recieverTb VERSION 1.0)
cmake_policy(SET CMP0074 NEW)

include(ProcessorCount)
ProcessorCount(NCPU)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if(NOT verilator_FOUND)
    message(
        FATAL_ERROR
        "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable"
    )
endif()
# 18ab4a2015df7f766caf52ae4720080de8ecd3cc
include(FetchContent)
FetchContent_Declare(
    svTest
    # Specify the commit you depend on and update it regularly.
    GIT_REPOSITORY https://github.com/mdhardenburgh/svTest.git
    GIT_TAG        ff31d93c3efe0dfa230edf5204dee604f6dbe020 # v1.0.00-pre-release
)
FetchContent_MakeAvailable(svTest)

# Create a new executable target that will contain all your sources
add_executable(${PROJECT_NAME} recieverTb.cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE src svTest)
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)


# fetch interface library file lists:
get_target_property(tbTestFiles src INTERFACE_SOURCES)
get_target_property(svTestFiles svTest INTERFACE_SOURCES)

get_target_property(uartIncDirs src INTERFACE_INCLUDE_DIRECTORIES)

# Put them (plus tb.sv itself) into one variable:
set(allSources
  ${tbTestFiles}
  ${svTestFiles}
  recieverTb.sv
)
# -Wno-{warning-code}
set(ARGS -Wno-DECLFILENAME -Wall -Wpedantic --assert --timing)
#set(ARGS -Wno-LATCH -Wno-UNOPTFLAT -Wno-INITIALDLY -Wno-MULTIDRIVEN -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --assert --timing)

# -j$(nproc)
# Add the Verilated circuit to the target
verilate(${PROJECT_NAME}
    SOURCES ${allSources}
    PREFIX ${PROJECT_NAME}
    TOP_MODULE ${PROJECT_NAME}
    THREADS ${NCPU}
    VERILATOR_ARGS ${ARGS}
    INCLUDE_DIRS ${uartIncDirs}
)