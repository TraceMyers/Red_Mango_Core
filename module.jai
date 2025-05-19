#load "meta.jai";
#load "testing.jai";
#load "bit_array.jai";
#load "math.jai";
#load "print_utils.jai";
#load "vector.jai";
#load "number_interpretation.jai";
#load "logging.jai";
#load "array_utils.jai";
#load "serialize.jai";
#load "string.jai";
#load "encode_text.jai";
#load "scope.jai";
#load "pool.jai";

RUN_TESTS :: true;
SAFE_TEXT_ENCODING :: true;
SERIALIZE_DEBUG :: false;

#scope_module // -------------------------------------------------------------------------------------------- { MODULE }

#import "Basic";
#import "Math";
#import "File";
#import "Thread";
#import "String";
Program_Print :: #import "Program_Print";
Compiler :: #import "Compiler";

#if RUN_TESTS {
    #load "tests.jai";
    #import "Random";
    tests := Test_Proc.[
        bit_array_test,
        text_encoding_test,
        math_test,
        array_utils_test,
        pool_test,
        misc_test
    ];
    #run run_tests("red mango module", tests);
}
