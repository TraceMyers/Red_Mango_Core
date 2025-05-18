
code_string :: ($code: Code, allocator := temp) -> string {
    builder: String_Builder;
    builder.allocator = allocator;
    assert(Program_Print.print_expression(*builder, Compiler.compiler_get_nodes(code)));
    return builder_to_string(*builder);
}

is_type :: (info: *Type_Info, base_name: string) -> bool {
    if info.type != .STRUCT return false;
    info_struct := cast(*Type_Info_Struct) info;
    return info_struct.name == base_name;
}

is_subtype :: (info: *Type_Info, base_name: string, $check_equal_base_type := false) -> bool {
    #if (check_equal_base_type) {
        using Type_Info_Tag;
        if info.type != STRUCT return false;
        info_struct := cast(*Type_Info_Struct) info;
        if info_struct.name == base_name {
            return true;
        }
    }
    return Compiler.is_subclass_of(info, base_name);
}
