
Endianness :: enum u8 {
    LITTLE;
    BIG;
}

read_number_from_binary :: inline (bin: string, position: s64, $Number_Type: Type, endianness := Endianness.LITTLE) -> Number_Type 
#modify {
    info := cast(*Type_Info)Number_Type;
    if info.type == .INTEGER || info.type == .FLOAT{
        return info.runtime_size >= 1 && info.runtime_size <= 8;
    }
    return false;
} {
    // backing int type
    #if size_of(Number_Type) == 8 {
        T :: u64;
    } else #if size_of(Number_Type) == 4 {
        T :: u32;
    } else #if size_of(Number_Type) == 2 {
        T :: u16;
    } else {
        T :: u8;
    }

    raw_val: T = ---;
    if endianness == .LITTLE {
        #if size_of(T) == {
        case 8;
            raw_val = (bin[position+0].(T) << 56) | (bin[position+1].(T) << 48) | (bin[position+2].(T) << 40) | (bin[position+3] << 32)
                    | (bin[position+4].(T) << 24) | (bin[position+5].(T) << 16) | (bin[position+6].(T) << 08) | (bin[position+7] << 00);
        case 4;
            raw_val = (bin[position+0].(T) << 24) | (bin[position+1].(T) << 16) | (bin[position+2].(T) << 8) | (bin[position+3]);
        case 2;
            raw_val = (bin[position+1].(T) << 8) | (bin[position+0]);
        case 1;
            raw_val = bin[position+0];
        }
    } else {
        #if size_of(T) == {
        case 8;
            raw_val = (bin[position+0].(T) << 00) | (bin[position+1].(T) << 08) | (bin[position+2].(T) << 16)  | (bin[position+3] << 24)
                    | (bin[position+4].(T) << 32) | (bin[position+5].(T) << 40) | (bin[position+6].(T) << 48)  | (bin[position+7] << 56);
        case 4;
            raw_val = (bin[position+0].(T) << 00) | (bin[position+1].(T) << 08) | (bin[position+2].(T) << 16)  | (bin[position+3] << 24);
        case 2;
            raw_val = (bin[position+0].(T) << 00) | (bin[position+1].(T) << 08);
        case 1;
            raw_val = bin[position+0];
        }
    }

    return (*raw_val).(*Number_Type).*;
}

Binary_Reader :: struct {
    memory: string;
    position: s64;
}

// read_number :: (reader: *Binary_Reader, $Number_Type: Type, endianness := Endianness.LITTLE) -> Number_Type {
//     val := read_number_from_binary(reader.memory, reader.position, Number_Type, endianness);
//     reader.position += size_of(Number_Type);
//     return val;
// }

// read_string :: (using reader: *Binary_Reader, count: s64) -> string {
//     assert(position + count <= memory.count);
//     val := string.{count, memory.data + position};
//     position += count;
//     return val;
// }

// read_array :: (using reader: *Binary_Reader, $Number_Type: Type, count: s64, e := Endianness.LITTLE, allocator := context.allocator) -> []Number_Type {
//     old_position := position;
//     advance_count := count * size_of(Number_Type);
//     assert(position + advance_count <= memory.count);
//     out_array := alloc_array(Number_Type, allocator);
//     for *out_array {
//         it.* = read_number(reader, Number_Type, e);
//     }
//     assert(position == old_position + advance_count);
//     return out_array;
// }

// read_bytes :: (using reader: *Binary_Reader, buffer: *[]u8, count: s64) {
//     old_position := position;
//     assert(position + count <= memory.count);
//     assert(count <= buffer.count);
//     memcpy(buffer.data, memory.data + position, count);
//     reader.position += count;
// }

// // TODO: boil down serialization. one struct is probably fine.
// Aligned_Buffer_Writer :: struct {
//     memory: string;
//     position: s64;
// }

// write_number :: (using writer: *Aligned_Buffer_Writer, number: $Number_Type, $simulation := false) {
//     write_to_address := memory.data + position;

//     aligned_write_to_address := xx multiple_of_ceil(write_to_address.(u64), size_of(Number_Type));
//     if aligned_write_to_address != write_to_address {
//         advance(writer, aligned_write_to_address - write_to_address);
//     }
//     write_to_address = aligned_write_to_address;

//     new_position := position + size_of(Number_Type);
//     assert(new_position <= memory.count);
//     #if !simulation {
//         num_ptr := write_to_address.(*Number_Type);
//         num_ptr.* = number;
//     }
//     position = new_position;
// }

// advance :: (using writer: *Aligned_Buffer_Writer, byte_count: s64, $simulation := false) {
//     new_position := position + byte_count;
//     assert(new_position <= memory.count);
//     assert(byte_count > 0);
//     #if !simulation {
//         memset(memory.data + position, 0, byte_count);
//     }
//     position = new_position;
// }

// write_null_terminated_string :: (using writer: *Aligned_Buffer_Writer, str: string, $simulation := false) {
//     new_position := position + str.count + 1;
//     assert(new_position <= memory.count);
//     #if !simulation {
//         memcpy(memory.data + position, str.data, str.count);
//         memory.data[position + str.count] = 0;
//     }
//     position = new_position;
// }

// maybe_advance :: (using writer: *Aligned_Buffer_Writer, align_to_type)

// write_flattened_string :: (using writer: *Aligned_Buffer_Writer, str: string, $position_simulation := false) {
//     write_to_address := memory.data + position;

//     aligned_write_to_address := xx multiple_of_ceil(write_to_address.(u64), size_of(s64));
//     if aligned_write_to_address != write_to_address {
//         advance(writer, aligned_write_to_address - write_to_address);
//     }
//     write_to_address = aligned_write_to_address;

//     new_position := position + size_of(string) + str.count;
//     assert(new_position <= memory.count);

// }