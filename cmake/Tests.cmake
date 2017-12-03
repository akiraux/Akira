# Test macros for Marlin, feel free to re-use them.

macro(add_test_executable EXE_NAME)
    add_test(${EXE_NAME} gtester ${CMAKE_CURRENT_BINARY_DIR}/${EXE_NAME})
endmacro()
