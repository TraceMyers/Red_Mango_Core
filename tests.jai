bit_array_test :: () -> bool, string {
    auto_release_temp();
    single_bits: Bit_Array(1);
    set_capacity(*single_bits, 97);

    test_condition(single_bits.items.count == 2);

    test_condition(find_first_set_bit(*single_bits) == -1);
    set_bit(*single_bits, 33);
    test_condition(find_first_set_bit(*single_bits) == 33);
    test_condition(find_last_set_bit(*single_bits) == 33);
    set_bit(*single_bits, 35);
    test_condition(find_last_set_bit(*single_bits) == 35);
    set_bit(*single_bits, 92);
    test_condition(find_first_set_bit(*single_bits) == 33);
    set_bit(*single_bits, 93);
    set_bit(*single_bits, 94);
    set_bit(*single_bits, 95);
    set_bit(*single_bits, 96);

    test_condition(bit_is_set(*single_bits, 33));
    test_condition(bit_is_set(*single_bits, 35));
    test_condition(bit_is_set(*single_bits, 92));
    test_condition(bit_is_set(*single_bits, 93));
    test_condition(bit_is_set(*single_bits, 94));
    test_condition(bit_is_set(*single_bits, 95));
    test_condition(bit_is_set(*single_bits, 96));

    test_condition(find_last_unset_bit(*single_bits) == 91);
    unset_bit(*single_bits, 92);
    test_condition(find_last_unset_bit(*single_bits) == 92);
    unset_bit(*single_bits, 35);
    unset_bit(*single_bits, 36);

    unset_bit(*single_bits, 33);
    test_condition(find_first_set_bit(*single_bits) == 93);
    set_bit(*single_bits, 33);

    test_condition(find_last_set_bit(*single_bits) == 96);
    unset_bit(*single_bits, 96);
    test_condition(find_last_set_bit(*single_bits) == 95);

    test_condition(bit_is_set(*single_bits, 33));
    test_condition(!bit_is_set(*single_bits, 35));
    test_condition(!bit_is_set(*single_bits, 36));
    test_condition(!bit_is_set(*single_bits, 92));

    for 0..20 {
        if it == 10 || it == 15 {
            continue;
        }
        set_bit_group(*single_bits, it);
    }
    test_condition(find_first_unset_bit(*single_bits) == 10);
    test_condition(find_first_unset_bit(*single_bits, -1, 11) == 15);
    test_condition(find_first_unset_bit(*single_bits, -1, 15) == 15);
    test_condition(find_first_unset_bit(*single_bits, -1, 16) == 21);

    MULTI_BIT_CT :: 16;
    multi_bit_capacity := 97;
    multi_bits: Bit_Array(MULTI_BIT_CT);

    set_capacity(*multi_bits, multi_bit_capacity);

    bit_ct := MULTI_BIT_CT * multi_bit_capacity;
    u64_ct := bit_ct / 64;
    u64_ct += ifx (u64_ct * 64 == bit_ct) then 0 else 1;
    test_condition(multi_bits.items.count == u64_ct);

    set_bit(*multi_bits, 33);
    test_condition(find_last_group_with_set_bits(*multi_bits) == 33);
    test_condition(find_first_group_with_set_bits(*multi_bits) == 33);
    set_bit(*multi_bits, 35, 3);
    test_condition(find_first_group_with_set_bits(*multi_bits) == 33);
    set_bit(*multi_bits, 92, 15);
    test_condition(find_last_group_with_set_bits(*multi_bits, 3) == 35);
    test_condition(find_last_group_with_set_bits(*multi_bits) == 92);
    set_bit_group(*multi_bits, 93);
    set_bit_group(*multi_bits, 91);

    set_bit_group(*multi_bits, 94);
    set_bit_group(*multi_bits, 95);
    set_bit_group(*multi_bits, 96);

    unset_bit(*multi_bits, 94, 1);
    test_condition(find_last_group_with_unset_bits(*multi_bits, 1) == 94);
    set_bit(*multi_bits, 94, 1);

    test_condition(find_last_group_with_unset_bits(*multi_bits) == 92);
    unset_bit_group(*multi_bits, 94);
    test_condition(find_last_group_with_unset_bits(*multi_bits) == 94);
    unset_bit_group(*multi_bits, 95);
    unset_bit_group(*multi_bits, 96);

    test_condition(bit_is_set(*multi_bits, 33));
    test_condition(bit_is_set(*multi_bits, 35, 3));
    test_condition(bit_is_set(*multi_bits, 92, 15));
    test_condition(all_bits_in_group_set(*multi_bits, 93));
    test_condition(all_bits_in_group_set(*multi_bits, 91));
    test_condition(!any_bits_in_group_set(*multi_bits, 94));

    unset_bit(*multi_bits, 35, 3);
    unset_bit(*multi_bits, 36, 5);
    unset_bit(*multi_bits, 33);
    test_condition(find_first_group_with_set_bits(*multi_bits) == 91);
    set_bit(*multi_bits, 33);
    unset_bit(*multi_bits, 92, 15);

    test_condition(bit_is_set(*multi_bits, 33));
    test_condition(!any_bits_in_group_set(*multi_bits, 35));
    test_condition(!any_bits_in_group_set(*multi_bits, 36));
    test_condition(!any_bits_in_group_set(*multi_bits, 92));

    unset_bit(*multi_bits, 33);

    for 0..13 {
        if it == 9 || it == 12 {
            continue;
        }
        set_bit_group(*multi_bits, it);
    }
    test_condition(find_first_group_with_unset_bits(*multi_bits) == 9);
    test_condition(find_first_group_with_unset_bits(*multi_bits, -1, 10) == 12);
    test_condition(find_first_group_with_unset_bits(*multi_bits, -1, 12) == 12);
    test_condition(find_first_group_with_unset_bits(*multi_bits, -1, 13) == 14);

    unset_bit(*multi_bits, 2, 0);
    test_condition(find_first_group_with_unset_bits(*multi_bits) == 2);

    set_bit_group(*multi_bits, 9);
    set_bit_group(*multi_bits, 12);
     for 0..11 {
        unset_bit(*multi_bits, it, it);
    }
    test_condition(find_first_group_with_unset_bits(*multi_bits, 9) == 9);

    reset(*single_bits);
    reset(*multi_bits);

    return_test_success();
}

text_encoding_test :: () -> bool, string {
    auto_release_temp();

    utf8_real_world_file := tprint("%/test_supplemental/utf8_in.txt", #filepath);
    utf8_real_world, read_utf8_real_world_success := read_entire_file(utf8_real_world_file);
    test_condition(read_utf8_real_world_success);
    encode_success: bool;

    str_a := "abc";
    str_b := copy_string(str_a);
    // some test conditions are predicated on '==' operator working like strcmp rather than just comparing pointers and counts. keeping this here in case the compiler changes the way this works, because this language is in closed beta and the compiler is volatile. this almost certainly won't change but who knows.
    test_condition(str_a == str_b); 

    // starting with real world utf8 and moving it through all of the translation paths
    {
        // this uses utf16 <-> utf32 as a transition state for each code point, so that is also tested somewhat
        to_utf16:, encode_success = encode_temp_text(utf8_real_world, .UTF8, .UTF16);
        test_condition(encode_success);
        back_to_utf8:, encode_success = encode_temp_text(to_utf16, .UTF16, .UTF8);
        test_condition(encode_success);
        test_condition(utf8_real_world == back_to_utf8);

        loopback_utf16:, encode_success = encode_temp_text(to_utf16, .UTF16, .UTF16);
        test_condition(encode_success);
        loopback_utf8:, encode_success = encode_temp_text(back_to_utf8, .UTF8, .UTF8);
        test_condition(encode_success);

        test_condition(to_utf16 == loopback_utf16);
        test_condition(utf8_real_world == loopback_utf8);
    }
    {
        to_utf32:, encode_success = encode_temp_text(utf8_real_world, .UTF8, .UTF32);
        test_condition(encode_success);
        back_to_utf8:, encode_success = encode_temp_text(to_utf32, .UTF32, .UTF8);
        test_condition(encode_success);
        test_condition(utf8_real_world == back_to_utf8);

        loopback_utf32:, encode_success = encode_temp_text(to_utf32, .UTF32, .UTF32);
        test_condition(encode_success);

        test_condition(to_utf32 == loopback_utf32);
    }
    {
        to_ansi:, encode_success = encode_temp_text(utf8_real_world, .UTF8, .ANSI);
        test_condition(!encode_success);
    }

    ansi_val := "\xff";
    ansi_to_utf8:, encode_success = encode_temp_text(ansi_val, .ANSI, .UTF8);
    test_condition(encode_success);
    test_condition(ansi_to_utf8.count == 2);

    bad_utf8_1 := "\xf0\x02";
    bad_utf8_to_utf32_1:, encode_success = encode_temp_text(bad_utf8_1, .UTF8, .UTF32);
    test_condition(!encode_success);

    bad_utf8_2 := "\xe1\x81";
    bad_utf8_to_utf32_2:, encode_success = encode_temp_text(bad_utf8_2, .UTF8, .UTF32);
    test_condition(!encode_success);

    bad_utf32 := "\x01\x02\x03";
    bad_utf32_to_utf16:, encode_success = encode_temp_text(bad_utf32, .UTF32, .UTF16);
    test_condition(!encode_success);

    unaligned_utf16 := "\x00\x01\x02";
    addr_is_even := (unaligned_utf16.data.(u64) & 1) == 0;
    if addr_is_even {
        unaligned_utf16.data += 1;
    }
    else {
        unaligned_utf16[0] = unaligned_utf16[1];
        unaligned_utf16[1] = unaligned_utf16[2];
    }
    unaligned_utf16.count -= 1;
    unaligned_utf16_to_utf32:, encode_success = encode_temp_text(unaligned_utf16, .UTF16, .UTF32);
    test_condition(encode_success);
    test_condition(unaligned_utf16_to_utf32.count == 4);
    test_condition(unaligned_utf16_to_utf32 == "\x01\x02\x00\x00");

    return_test_success();
}

math_test :: () -> bool, string {
    // seems silly to test this but it's free so whatever
    test_condition(!is_power_of_two(65));
    test_condition(!is_power_of_two(-1));
    for i : 0..63 {
        pow2 : u64 = (1).(u64) << i.(u64);
        test_condition(is_power_of_two(pow2));
        if i > 1 {
            test_condition(!is_power_of_two(pow2-1));
        }
    }

    {
        val := 5;
        min := 2;
        max := 8;
        add_to_val := 20;
        result := add_wrap(val, add_to_val, min, max);
        test_condition(result == 4);
    }
    {
        val := 11;
        min := 2;
        max := 12;

        add_to_val := 2;
        result := add_wrap(val, add_to_val, min, max);
        test_condition(result == min);

        add_to_val = 2 + (max - min);
        result = add_wrap(val, add_to_val, min, max);
        test_condition(result == max);

        val = 3;
        add_to_val = max - val;
        result = add_wrap(val, add_to_val, min, max);
        test_condition(result == max);

        add_to_val = -1;
        result = add_wrap(val, add_to_val, min, max);
        test_condition(result == min);

        add_to_val = -2;
        result = add_wrap(val, add_to_val, min, max);
        test_condition(result == max);

        add_to_val = -2 - (max-min);
        result = add_wrap(val, add_to_val, min, max);
        test_condition(result == min);

        add_to_val -= 1;
        result = add_wrap(val, add_to_val, min, max);
        test_condition(result == max);

        val = 2;
        min = 2;
        max = 2;
        add_to_val = 20;
        result = add_wrap(val, add_to_val, min, max);
        test_condition(result == 2);

        add_to_val = -20;
        result = add_wrap(val, add_to_val, min, max);
        test_condition(result == 2);
    }
    {
        int_val : u8 = 127;
        norm_val := alter_cast(int_val, float, true);
        test_condition(abs(norm_val-0.5) <= 0.005);

        int_val = 0;
        norm_val = alter_cast(int_val, float, true);
        test_condition(norm_val == 0.0);

        int_val = 255;
        norm_val = alter_cast(int_val, float, true);
        test_condition(norm_val == 1.0);

        float_val := 0.0;
        out_int := alter_cast(float_val, s8, false, false);
        test_condition(out_int == 0);

        float_val = 1.0;
        out_int = alter_cast(float_val, s8, true, false);
        test_condition(out_int == 127);

        float_val = 1.0;
        out_int = alter_cast(float_val, s8, true, true);
        test_condition(out_int == 127);

        float_val = xx S32_MAX;
        out_int2 := alter_cast(float_val, s32, false, false);
        // overflow on cast back to int
        test_condition(out_int2 == S32_MIN);

        out_int2 = alter_cast(float_val, s32, false, true);
        // round() clamps to stop the overflow
        test_condition(out_int2 == S32_MAX);

        have_to_assign_to_var_or_cast_doesnt_work_right : s32 = S32_MIN;
        float_val = have_to_assign_to_var_or_cast_doesnt_work_right.(float) - 128.0;
        out_int2 = alter_cast(float_val, s32, false, true);
        // round() clamps to stop the underflow
        test_condition(out_int2 == S32_MIN);
    }
    {
        f := 1.99999;
        floored := floor(f, s32, .TOWARD_ZERO);
        ceiled := ceil(f, s32, .TOWARD_POSITIVE_INFINITY);
        rounded := round(f);
        test_condition(floored == 1);
        test_condition(ceiled == 2);
        test_condition(rounded == 2);
        floored = floor(f, s32, .TOWARD_NEGATIVE_INFINITY);
        ceiled = ceil(f, s32, .AWAY_FROM_ZERO);
        test_condition(floored == 1);
        test_condition(ceiled == 2);

        f = 1.00001;
        floored = floor(f, s32, .TOWARD_ZERO);
        ceiled = ceil(f, s32, .TOWARD_POSITIVE_INFINITY);
        rounded = round(f);
        test_condition(floored == 1);
        test_condition(ceiled == 2);
        test_condition(rounded == 1);
        floored = floor(f, s32, .TOWARD_NEGATIVE_INFINITY);
        ceiled = ceil(f, s32, .AWAY_FROM_ZERO);
        test_condition(floored == 1);
        test_condition(ceiled == 2);

        f = -1.99999;
        floored = floor(f, s32, .TOWARD_ZERO);
        ceiled = ceil(f, s32, .TOWARD_POSITIVE_INFINITY);
        rounded = round(f);
        test_condition(floored == -1);
        test_condition(ceiled == -1);
        test_condition(rounded == -2);
        floored = floor(f, s32, .TOWARD_NEGATIVE_INFINITY);
        ceiled = ceil(f, s32, .AWAY_FROM_ZERO);
        test_condition(floored == -2);
        test_condition(ceiled == -2);

        f = -1.00001;
        floored = floor(f, s32, .TOWARD_ZERO);
        ceiled = ceil(f, s32, .TOWARD_POSITIVE_INFINITY);
        rounded = round(f);
        test_condition(floored == -1);
        test_condition(ceiled == -1);
        test_condition(rounded == -1);
        floored = floor(f, s32, .TOWARD_NEGATIVE_INFINITY);
        ceiled = ceil(f, s32, .AWAY_FROM_ZERO);
        test_condition(floored == -2);
        test_condition(ceiled == -2);
    }
    {
        a: s32 = 8;
        b := ceil_to_multiple(a, 8);
        c := floor_to_multiple(a, 8);
        test_condition(b == 8);
        test_condition(c == 8);

        a = 9;
        b = ceil_to_multiple(a, 8);
        c = floor_to_multiple(a, 8);
        test_condition(b == 16);
        test_condition(c == 8);

        a = 7;
        b = ceil_to_multiple(a, 8);
        c = floor_to_multiple(a, 8);
        test_condition(b == 8);
        test_condition(c == 0);
    }

    return_test_success();
}

array_utils_test :: () -> bool, string {
    auto_release_temp();
    {
        base_array := u32.[0, 1, 2, 3];
        bound := bound_array(base_array);
        first_changed_val : u32 = 4;
        bound_array_add(*bound, first_changed_val);
        bound_array_add(*bound, first_changed_val+1);
        bound_array_append(*bound, u32.[first_changed_val+2, first_changed_val+3]);
        overwrite_as_expected := true;
        for 0..3 {
            if base_array[it] != first_changed_val + it {
                overwrite_as_expected = false;
                break;
            }
        }
        test_condition(overwrite_as_expected);
        test_condition(bound.max == bound.array.count);
    }
    {
        arr := string.["hello", "yes", "fishy joe"];
        pointer_based_index := array_element_index(arr, *arr[1]);
        success, found_index := array_find(arr, "yes");
        test_condition(pointer_based_index == found_index);
    }
    {
        arr1 := s32.[1, 2, 3];
        arr2 := s32.[1, 2, 3, 4];
        test_condition(!arrays_equal(arr1, arr2));
        arr3 : []s32 = arr2;
        arr3.count -= 1;
        test_condition(arrays_equal(arr1, arr3));
    }
    {
        arr1 := temp_dynamic_array(s32, 2);
        arr2 := s32.[1, 2, 3, 4];
        array_append(*arr1, arr2);
        test_condition(arrays_equal(arr1, arr2));

        arr3 := concatenate(arr1, arr2);
        arr_compare := s32.[1,2,3,4,1,2,3,4];
        test_condition(arrays_equal(arr3, arr_compare));

        arr4 := duplicate(arr3);
        test_condition(arrays_equal(arr3, arr4));
    }

    return_test_success();
}

pool_test :: () -> bool, string {
    auto_release_temp();
    SomeStruct :: struct {
        a : s32 = -1;
        b := 1.0;
        c := "a string!";
    }

    init_item_proc :: (s: *SomeStruct) {
        assert(s.a == -1 && s.b == 1.0 && s.c == "a string!");
        s.a = 100;
        s.b = 100.0;
        s.c = "neh";
    }

    deinit_item_proc :: (s: *SomeStruct) {
        assert(s.a == 100 && s.b == 100.0 && s.c == "neh");
        s.* = .{};
    }

    p: Pool(SomeStruct);
    p.shrink_to_min = 0;
    set_capacity(*p, 32);

    i1 := request_item(*p, init_item_proc);
    s1 := *p[i1];
    test_condition(s1 == *p[0]);

    i2 := request_item(*p, init_item_proc);
    s2 := *p[i2];
    test_condition(s2 == *p[1]);

    i3 := request_item(*p, init_item_proc);
    s3 := *p[i3];
    test_condition(s3 == *p[2]);

    return_item(*p, i2, deinit_item_proc);
    test_condition(p.top == 2);
    test_condition(!is_item_in_use(*p, 1));

    i3b := get_item_index(*p, s3);
    test_condition(i3b == i3);

    i2 = request_item(*p, init_item_proc);
    s2 = *p[i2];
    test_condition(s2 == *p[1]);
    test_condition(is_item_in_use(*p, 1));

    compare_proc :: (a: *SomeStruct, b: *SomeStruct) -> bool {
        return a == b;
    }

    i3c := find_item(*p, s3, compare_proc);
    test_condition(i3c == i3);

    // --
    reset(*p, deinit_item_proc);
    // --

    i1 = request_item(*p, init_item_proc);
    s1 = *p[i1];
    test_condition(s1 == *p[0]);

    i2 = request_item(*p, init_item_proc);
    s2 = *p[i2];
    test_condition(s2 == *p[1]);

    i3 = request_item(*p, init_item_proc);
    s3 = *p[i3];
    test_condition(s3 == *p[2]);

    return_item(*p, i2, deinit_item_proc);
    test_condition(p.top == 2);
    test_condition(!is_item_in_use(*p, 1));

    i3b = get_item_index(*p, s3);
    test_condition(i3b == i3);

    i2 = request_item(*p, init_item_proc);
    s2 = *p[i2];
    test_condition(s2 == *p[1]);
    test_condition(is_item_in_use(*p, 1));

    i3c = find_item(*p, s3, compare_proc);
    test_condition(i3c == i3);
    
    // --
    reset(*p, deinit_item_proc);
    // --
    
    indices := temp_dynamic_array(s64, 100);
    for 0..99 {
        request_item(*p, init_item_proc);
        array_add(*indices, it);
    }

    shuffle_array :: (arr: []$T) {
        if arr.count == 0 then return;
        for i: 0..arr.count-1 {
            rand_val := random_get_zero_to_one_new();
            swap_index := round(respace(xx rand_val, .{0.0, 1.0}, .{0.0, xx (arr.count-1)}));
            arr[i], arr[swap_index] = arr[swap_index], arr[i];
        }
    }

    test_condition(find_last_set_bit(*p.in_use) == 99);
    shuffle_array(indices);

    for indices {
        return_item(*p, it, deinit_item_proc);
    }

    test_condition(p.top == -1);
    test_condition(p.items.count == 0);
    test_condition(find_first_set_bit(*p.in_use) == -1);

    p.shrink_to_min = 12;
    for 0..99 {
        request_item(*p, init_item_proc);
    }
    for indices {
        return_item(*p, it, deinit_item_proc);
    }

    test_condition(p.top == -1);
    test_condition(p.items.count >= 12);

    return_test_success();
}

// mostly for sanity testing before a commit. tests in here likely aren't precious.
misc_test :: () -> bool, string {
    auto_release_temp();
    {
        k: [9]u64;
        k[2] = 20;
        zero_array(k);
        test_condition(k[2] == 0);
    }
    {
        b: Bound_Local_Array(s32, 8);
        bound_local_array_init(*b);
        bound_local_array_add(*b, 1);
        bound_local_array_add(*b, 1);
        bound_local_array_add(*b, 1);
        bound_local_array_add(*b, 1);
        test_condition(arrays_equal(b.array, s32.[1, 1, 1, 1]));
    }

    return_test_success();
}
