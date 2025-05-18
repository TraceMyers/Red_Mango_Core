is_number_type :: (In_Type: Type) -> bool {
    return (cast(*Type_Info)In_Type).type == .INTEGER || (cast(*Type_Info)In_Type).type == .FLOAT;
}

is_int_type :: (In_Type: Type) -> bool {
    return (cast(*Type_Info)In_Type).type == .INTEGER;
}

is_float_type :: (In_Type: Type) -> bool {
    return (cast(*Type_Info)In_Type).type == .FLOAT;
}

min_value :: inline (number: $Number_Type) -> Number_Type #expand {
    return min_value(type_of(number));
}

max_value :: inline (number: $Number_Type) -> Number_Type #expand {
    return max_value(type_of(number));
}

min_value :: ($Number_Type: Type) -> Number_Type
#modify {
    return is_number_type(Number_Type);
} {
    #if Number_Type == {
    case u8;
        return 0;
    case u16; 
        return 0;
    case u32; 
        return 0;
    case u64;
        return 0;
    case s8;
        return S8_MIN;
    case s16;
        return S16_MIN;
    case s32;
        return S32_MIN;
    case s64;
        return S64_MIN;
    case float32;
        return FLOAT32_MIN;
    case float64;
        return FLOAT64_MIN;
    case;
        return 0;
    }
}

max_value :: ($Number_Type: Type) -> Number_Type
#modify {
    return is_number_type(Number_Type);
} {
    #if Number_Type == {
    case u8;
        return U8_MAX;
    case u16;
        return U16_MAX;
    case u32;
        return U32_MAX;
    case u64;
        return U64_MAX;
    case s8;
        return S8_MAX;
    case s16;
        return S16_MAX;
    case s32;
        return S32_MAX;
    case s64;
        return S64_MAX;
    case float32;
        return FLOAT32_MAX;
    case float64;
        return FLOAT64_MAX;
    case;
        return 0;
    }
}