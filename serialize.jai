
// todo: bit & struct packing

Serializer_Alloc_Mode :: enum u8 {
    STATIC;
    DYNAMIC;
};

Serializer_Align_Mode :: enum u8 {
    BYTE;
    PRIMITIVE;
    PARAMETER;
}

Serializer :: struct($in_alloc_mode: Serializer_Alloc_Mode = .STATIC, $in_align_mode: Serializer_Align_Mode = .BYTE) {
    memory: []u8;
    // TODO: parallel array of tags. push on write, pop on read. check against T.
    // #if SERIALIZE_DEBUG {
        // dbg_tags: [..]Type_Info_Tag;
    //     dbg_i: s64;
    // }
    allocator: Allocator; // only used if dynamic
    read_array_allocator: Allocator; // used only when reading out arrays
    head: s64;
    bit_head: u8;
    parameter_align : u8 = 1; // must be power of 2 if used
    rw_mode: enum u8 {
        WRITE;
        READ;
    };
    alloc_mode :: in_alloc_mode;
    align_mode :: in_align_mode;
}

serialize :: (buffer: *Serializer($alloc_m, $align_m), item: *$T) {
    if buffer.rw_mode == .WRITE {
        write(buffer, item);
    } else {
        read(buffer, item);
    }
}

reset :: (using buffer: *Serializer($alloc_m, $align_m), keep_allocation := true) {
    if !keep_allocation {
        array_free(memory);
        memory.data = null;
        memory.count  = 0;
    }
    // allocator = .{} keep allocator
    head = 0;
    bit_head = 0;
    // parameter_align = 1 keep constant align setting
    rw_mode = .WRITE;
}

write :: (using buffer: *Serializer($alloc_m, $align_m), item: *$T) 
#modify {
    return is_serial_primitive(T);
} {
    align_head_up_for_type(buffer, T);
    new_head := head + size_of(T);
    serializer_check_new_head(buffer, new_head);
    serializer_write_primitive(buffer, item);
    head = new_head;
}

write :: (using buffer: *Serializer($alloc_m, $align_m), array: *[]$T) 
#modify {
    return is_serial_primitive(T);
} {
    assert(array.count <= U32_MAX);
    if array.count != 0 {
        align_head_up_for_type(buffer, T);
        array_size := size_of(T) * array.count;
        new_head := head + array_size;
        serializer_check_new_head(buffer, new_head);
        memcpy(memory.data + head, array.data, array.count * size_of(T));
        head = new_head;
    }
    array_count: u32 = xx array.count;
    assert(array.count < (1 << 28));

    pre_write_num_head := head;
    write(buffer, *array_count);
    count_in_buffer : *u32 = (*buffer.memory[head-4]).(*u32);
    head_diff := (head - pre_write_num_head);
    assert(head_diff >= 0);
    head_diff -= 4;
    count_in_buffer.* |= head_diff.(u32) << 28;
}

write :: (using buffer: *Serializer($alloc_m, $align_m), str: *string) {
    array := as_array(str.*, u8);
    write(buffer, *array);
}


read :: (using buffer: *Serializer($alloc_m, $align_m), item: *$T) 
#modify {
    return is_serial_primitive(T);
} {
    #if buffer.align_mode != .BYTE {
        rm_error("Serializer can only read in BYTE mode");
        return;
    }
    head -= size_of(T);
    align_head_down_for_type(buffer, T);
    serializer_read_primitive(buffer, item);
}

read :: (using buffer: *Serializer($alloc_m, $align_m), array: *[]$T) 
#modify {
    return is_serial_primitive(T);
} {
    #if buffer.align_mode != .BYTE {
        rm_error("Serializer can only read in BYTE mode");
        return;
    }
    assert(array.data == null && array.count == 0);
    array_count: u32;
    read(buffer, *array_count);
    // we may need to move the head back. if so, the number of moves is in the top bits of array_count
    retract_count := (array_count & 0xf000_0000) >> 28;
    array_count &= ~(0xf000_0000).(u32);
    if retract_count > 0 {
        retract_head(buffer, retract_count);
    }
    if array_count > 0 {
        array.* = alloc_array(T, array_count, read_array_allocator);
        array_size := array_count * size_of(T);
        head -= array_size;
        align_head_down_for_type(buffer, T);
        memcpy(array.data, memory.data + head, array_size);
    }
}

read :: (using buffer: *Serializer($alloc_m, $align_m), str: *string) {
    #if buffer.align_mode != .BYTE {
        rm_error("Serializer can only read in BYTE mode");
        return;
    }
    array: []u8;
    read(buffer, *array);
    str.data = array.data;
    str.count = array.count;
}

write_array_count_and_pointer :: (using buffer: *Serializer($alloc_m, $align_m), array: *[]$T) 
#modify {
    return is_serial_primitive(T);
} {
    count : s64 = array.count;
    data : s64 = xx array.data;
    write(buffer, *count);
    write(buffer, *data);
}

read_array_count_and_pointer :: (using buffer: *Serializer($alloc_m, $align_m), array: *[]$T) 
#modify {
    return is_serial_primitive(T);
} {
    #if buffer.align_mode != .BYTE {
        rm_error("Serializer can only read in BYTE mode");
        return;
    }
    assert(array.data == null && array.count == 0);
    count, data: s64;
    read(buffer, *data);
    read(buffer, *count);
    array.data = data;
    array.count = count;
}

#scope_file // ------------------------------------------------------------------------------------------------ { FILE }

advance_head :: inline (using buffer: *Serializer($alloc_m, $align_m), by_count: s64) {
    new_head := head + by_count;
    assert(by_count > 0);
    assert(head >= 0 && head <= memory.count);
    assert(new_head >= 0 && new_head <= memory.count);
    head = new_head;
}

retract_head :: inline (using buffer: *Serializer($alloc_m, $align_m), by_count: s64) {
    new_head := head - by_count;
    assert(by_count > 0);
    assert(head >= 0 && head <= memory.count);
    assert(new_head >= 0 && new_head <= memory.count);
    head = new_head;
}

align_head_up :: (using buffer: *Serializer($alloc_m, $align_m), align: u8) {
    bit_head = 0;
    new_head := pow2_align_ceil(head, align);
    diff := new_head - head;
    if diff > 0 {
        advance_head(buffer, diff);
    } else assert(diff == 0);
}

align_head_down :: (using buffer: *Serializer($alloc_m, $align_m), align: u8) { 
    bit_head = 0;
    new_head := pow2_align_floor(head, align);
    diff := head - new_head;
    if diff > 0 {
        retract_head(buffer, diff);
    } else assert(diff == 0);
}

align_head_up_for_type :: (using buffer: *Serializer($alloc_m, $align_m), $T: Type) {
    align_head_up(buffer, serial_primitive_alignment(buffer, T));
}

align_head_up_for_array :: (using buffer: *Serializer($alloc_m, $align_m), $T: Type) {
    #if #complete align_mode == {
    case .PRIMITIVE;
        align_head_up(buffer, 4);
    case .PARAMETER;
        align_head_up(buffer, parameter_align);
    }
}

align_head_down_for_type :: (using buffer: *Serializer($alloc_m, $align_m), $T: Type) {
    align_head_down(buffer, serial_primitive_alignment(buffer, T));
}

align_head_down_for_array :: (using buffer: *Serializer($alloc_m, $align_m), $T: Type) {
    #if #complete align_mode == {
    case .PRIMITIVE;
        align_head_down(buffer, 4);
    case .PARAMETER;
        align_head_down(buffer, parameter_align);
    }
}

serializer_check_new_head :: (using buffer: *Serializer($alloc_m, $align_m), new_head: s64) {
    assert(new_head >= 0);
    #if alloc_mode == .STATIC {
        assert(new_head <= memory.count);
    } else { // DYNAMIC
        desired_capacity := max(pow2_align_ceil(new_head, 2), 512);
        if memory.count < desired_capacity {
            scope_set_allocator(allocator);
            new_memory := alloc_array(u8, desired_capacity);
            memcpy(new_memory.data, memory.data, memory.count);
            free(memory.data);
            memory = new_memory;
        }
    }
}

serializer_write_primitive :: inline (using buffer: *Serializer($alloc_m, $align_m), primitive: *$T) {
    #if align_mode == {
    case .PRIMITIVE;
        (memory.data + head).(*T).* = primitive.*;
    case .PARAMETER;
        memcpy(memory.data + head, primitive, size_of(T));
    case .BYTE;
        memcpy(memory.data + head, primitive, size_of(T));
    }
}

serializer_read_primitive :: inline (using buffer: *Serializer($alloc_m, $align_m), primitive: *$T) {
    #if align_mode == {
    case .PRIMITIVE;
         primitive.* = (memory.data + head).(*T).*;
    case .PARAMETER;
        memcpy(primitive, memory.data + head, size_of(T));
    case .BYTE;
        memcpy(primitive, memory.data + head, size_of(T));
    }
}

serial_primitive_alignment :: inline (using buffer: *Serializer($alloc_m, $align_m), $T: Type) -> u8 {
    T_ALIGNMENT : u8 : #run align_of(T);
    #if #complete align_mode == {
    case .PRIMITIVE;
        return T_ALIGNMENT;
    case .PARAMETER;
        return parameter_align;
    case .BYTE;
        return 1;
    }
    return 1;
}

is_serial_primitive :: (T: Type) -> bool {
    info := cast(*Type_Info)T;
    if info.type == .INTEGER return true;
    if info.type == .FLOAT   return true;
    if info.type == .BOOL    return true;
    if info.type == .ENUM    return true;
    if info.type == .STRUCT  return true;
    if info.type == .POINTER return true;
    return false;
}