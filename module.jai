
// #module_parameters()(
//     FORE_X := 1.0,      FORE_Y := 0.0,      FORE_Z := 0.0,
//     RIGHT_X := 0.0,     RIGHT_Y := -1.0,    RIGHT_Z := 0.0,
//     UP_X := 0.0,        UP_Y := 0.0,        UP_Z := 1.0
// ); 

FORE_X :: 1.0;      FORE_Y :: 0.0;      FORE_Z :: 0.0;
RIGHT_X :: 0.0;     RIGHT_Y :: -1.0;    RIGHT_Z :: 0.0;
UP_X :: 0.0;        UP_Y :: 0.0;        UP_Z :: 1.0;

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
#load "nesting_allocator.jai";
#load "bit_ops.jai";
#load "bump_allocator.jai";
#load "file.jai";
#load "no_allocator.jai";

RUN_TESTS :: true;
SAFE_TEXT_ENCODING :: true;
SERIALIZE_DEBUG :: false;
NESTING_ALLOCATOR_DEBUG :: false;

MANGO_FORE  :: Vector3.{FORE_X, FORE_Y, FORE_Z};
MANGO_RIGHT :: Vector3.{RIGHT_X, RIGHT_Y, RIGHT_Z};
MANGO_UP    :: Vector3.{UP_X, UP_Y, UP_Z};

#scope_module // -------------------------------------------------------------------------------------------- { MODULE }

#import "Basic";
#import "Math";
#import "File";
#import "File_Utilities";
#import "Thread";
#import "String";
Program_Print :: #import "Program_Print";
Compiler :: #import "Compiler";

#if RUN_TESTS {
    #load "tests.jai";
    #import "Random";
    // used to just #run the code, but it's helpful to compile the code before running it - not just because
    // the #run may fail, but because allocators are different / appear to be in a different state at compile time 
    // than in a compiled program, leading to crashes in one and not the other.
    // could just make build script for it, but this is fine.
    main :: () {
        tests := Test_Proc.[
            bit_array_test,
            text_encoding_test,
            math_test,
            array_utils_test,
            pool_test,
            misc_test,
            // nesting_allocator_test,
            bump_allocator_test,
            serializer_test,
        ];
        run_tests("red mango module", tests);
    }
}
