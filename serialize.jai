
Byte_Serial_Buffer :: struct {
    bytes: [..]u8;
    deserialize_offset: s32;
    mode_switch: enum u32 {
        SERIALIZE;
        DESERIALIZE;
    }
}

// TODO: serialize specializations for arrays and strings, but optional
// TODO: serialize bits

clear :: (buf: *Byte_Serial_Buffer, keep_allocation := true) {
    if keep_allocation {
        array_reset_keeping_memory(*buf.bytes);
    } else {
        array_reset(*buf.bytes);
    }
    buf.deserialize_offset = 0;
    buf.mode_switch = .SERIALIZE;
}

serialize :: (buffer: *Byte_Serial_Buffer, item: *$T) {
    write_offset := buffer.bytes.count;
    write_size := size_of(T);
    #if SERIALIZE_DEBUG {
        info := cast(*Type_Info)T;
        type_tag := info.type;
        write_size += size_of(Type_Info_Tag);
    }
    array_resize(*buffer.bytes, write_offset + write_size, false);
    #if SERIALIZE_DEBUG {
        memcpy(buffer.bytes.data + write_offset, *type_tag, size_of(Type_Info_Tag));
        write_offset += size_of(Type_Info_Tag);
    }
    memcpy(buffer.bytes.data + write_offset, xx item, size_of(T));
}

deserialize :: (buffer: *Byte_Serial_Buffer, item: *$T) {
    #if SERIALIZE_DEBUG {
        unpacking_type_tag: Type_Info_Tag = ---;
        memcpy(*unpacking_type_tag, buffer.bytes.data + buffer.deserialize_offset, size_of(Type_Info_Tag));
        buffer.deserialize_offset += size_of(Type_Info_Tag);
        info := cast(*Type_Info)T;
        assert(info.type == unpacking_type_tag);
    }
    memcpy(xx item, buffer.bytes.data + buffer.deserialize_offset, size_of(T));
    buffer.deserialize_offset += size_of(T);
}

serialize_io :: (buffer: *Byte_Serial_Buffer, item: *$T) {
    if buffer.mode_switch == .SERIALIZE {
        serialize(buffer, item);
    } else {
        deserialize(buffer, item);
    }
}

serialize_string :: (buffer: *Byte_Serial_Buffer, str: *string) {

}

deserialize_string :: (buffer: *Byte_Serial_Buffer, str: *string, allocator := context.allocator) {

}

serialize_string_io :: (buffer: *Byte_Serial_Buffer, str: *string, allocator := context.allocator) {
    if buffer.mode_switch == .SERIALIZE {
        serialize_string(buffer, str);
    } else {
        deserialize_string(buffer, str, allocator);
    }
}

