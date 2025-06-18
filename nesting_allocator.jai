
// todo: 

Nesting_Allocator_Outer_Chunk :: struct ($MIN_ALLOCATION_SIZE: s64) {
    inner_chunks: [64][MIN_ALLOCATION_SIZE]u8;
}

Nesting_Allocator :: struct ($MIN_ALLOCATION_SIZE := 16) {
    using #as base: Allocator;
    parent_allocator: Allocator;
    chunk_lists: [..][]Nesting_Allocator_Outer_Chunk(MIN_ALLOCATION_SIZE);
    books: Nesting_Allocator_Books;
    books_allocated_size: s64;
    default_outer_chunk_count_per_list: s32 = 32;
    shrink_to_min_lists: s32 = 1;
    default_reserve_size: s32;

    CHUNKS_PER_HEAP :: 64;
    CHUNK_SIZE :: size_of(Nesting_Allocator_Outer_Chunk(MIN_ALLOCATION_SIZE));
    #run assert(is_power_of_two(MIN_ALLOCATION_SIZE));
}

Nesting_Allocator_Books :: struct {
    largest_gap_per_list: []u8;
    gap_list_of_lists: [][]u8;
    flag_list_of_lists: [][]u64;
}

build_nesting_allocator_books :: (using allocator: *Nesting_Allocator($MIN_ALLOCATION_SIZE), out_books: *Nesting_Allocator_Books) -> s64 {
    out_books.largest_gap_per_list.data = null;
    out_books.largest_gap_per_list.count = chunk_lists.count;
    out_books.gap_list_of_lists = alloc_array([]u8, chunk_lists.count, temp);
    out_books.flag_list_of_lists = alloc_array([]u64, chunk_lists.count, temp);

    gaps_data_size := chunk_lists.count;
    lists_data := books.largest_gap_per_list.data + gaps_data_size;
    offset := gaps_data_size;

    if chunk_lists.count > 0 {
        for 0..chunk_lists.count-1 {
            out_books.gap_list_of_lists[it].data = xx offset;
            out_books.gap_list_of_lists[it].count = chunk_lists[it].count;
            offset += chunk_lists[it].count;
        }
        // align for 64 bit flags
        offset = ceil_to_multiple(offset, 8);
        for 0..chunk_lists.count-1 {
            out_books.flag_list_of_lists[it].data = xx offset;
            out_books.flag_list_of_lists[it].count = chunk_lists[it].count;
            BYTES_PER_FLAG_SET :: 8;
            offset += chunk_lists[it].count * BYTES_PER_FLAG_SET;
        }
    }
    // how much to allocate for the books data.
    return out_books.gap_list_of_lists.count * size_of([]u8) + out_books.flag_list_of_lists.count * size_of([]u64);
}

initialize_nesting_allocator :: (using allocator: *Nesting_Allocator($MIN_ALLOC_SIZE), in_parent_allocator: Allocator, in_default_chunk_list_size := 0, add_chunk_lists := 1) {
    assert(chunk_lists.count == 0 && chunk_lists.data == null);
    allocator.* = .{};
    proc = #bake_arguments nesting_allocator_proc(min_alloc_size=MIN_ALLOC_SIZE);
    data = allocator;
    parent_allocator = in_parent_allocator;
    if in_default_chunk_list_size > 0 {
        default_reserve_size = xx in_default_chunk_list_size;
    } else {
        default_reserve_size = xx (CHUNK_SIZE * 64);
    }
    if add_chunk_lists > 0 {
        for 0..add_chunk_lists - 1 {
            add_chunk_list(allocator, default_reserve_size);
        }
    }
}

add_chunk_list :: (using allocator: *Nesting_Allocator($MIN_ALLOC_SIZE), min_bytes: s64) {
    scope_set_allocator(parent_allocator);
    chunk_list := array_add(*chunk_lists);
    alloc_chunk_count := max(div_ceil(min_bytes, CHUNK_SIZE), 2);
    if alloc_chunk_count < 8 && !did_small_chunk_count_warning {
        rm_warning("min bytes % leads to only % chunks being allocated per nesting allocator heap. the number of chunks per heap should probably be somewhere between 8 and 128", min_bytes, alloc_chunk_count);
        did_small_chunk_count_warning = true;
    }
    chunk_list.* = alloc_array(Nesting_Allocator_Outer_Chunk(MIN_ALLOC_SIZE), alloc_chunk_count);
    // zero_array(chunk_list.*); // shouldn't need this
    grow_nesting_allocator_books(allocator);    
}

nesting_allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void, $min_alloc_size: s64) -> *void {
    Nesting_Allocator_Type :: #run Nesting_Allocator(min_alloc_size);
    nesting_allocator := allocator_data.(*Nesting_Allocator_Type);
    if mode == {
    case .ALLOCATE;
        return nesting_allocator_allocate(nesting_allocator, size);
    case .RESIZE;
        return nesting_allocator_resize(nesting_allocator, size, old_size, old_memory);
    case .FREE;
        nesting_allocator_free(nesting_allocator, old_memory);
    case .SHUTDOWN;
        nesting_allocator_shutdown();
    case;
        log("tried to use a nesting allocator with mode %, which it isn't prepared to handle", mode);
    };
    return null;
}

nesting_allocator_allocate :: (using allocator: *Nesting_Allocator($MIN_ALLOC_SIZE), size: s64) -> *void {
    alloc_inner_chunk_count := div_ceil(size, MIN_ALLOC_SIZE);
    assert(alloc_inner_chunk_count <= 64);
    alloc_mask: u64 = ((1).(u64) << alloc_inner_chunk_count) - (1).(u64);
    for *largest_gap : books.largest_gap_per_list {
        if largest_gap.* >= alloc_inner_chunk_count {
            max_gap: u8;
            data: *void;
            outer_list_index := it_index; 
            for *gap : books.gap_list_of_lists[outer_list_index] {
                if data == null && gap.* >= alloc_inner_chunk_count {
                    flag_set := *books.flag_list_of_lists[outer_list_index][it_index];
                    alloc_index := find_index_of_missing_bit_sequence_lsb(flag_set.*, alloc_mask, alloc_inner_chunk_count);
                    flag_set.* |= alloc_mask << alloc_index;
                    gap.* = xx largest_gap_in_bit_sequence_lsb(flag_set.*);
                    data = *chunk_lists[outer_list_index][alloc_index];
                }
                max_gap = max(max_gap, gap.*);
            }
            assert(data != null);
            largest_gap.* = max_gap;
            return data;
        }
    }
    
    // didn't find existing space, need to grow
    add_chunk_list(allocator, max(size, default_reserve_size));

    return null;
}

nesting_allocator_resize :: (using allocator: *Nesting_Allocator($MIN_ALLOC_SIZE), size: s64, old_size: s64, old_memory: *void) -> *void {
    return null;
}

nesting_allocator_free :: (using allocator: *Nesting_Allocator($MIN_ALLOC_SIZE), old_memory: *void) {
}

nesting_allocator_shutdown :: () {
}

// assumes the number of chunk_lists has grown by 1
grow_nesting_allocator_books :: (using allocator: *Nesting_Allocator($MIN_ALLOCATION_SIZE)) {
    scope_set_allocator(parent_allocator);
    // auto_release_temp();
    assert(chunk_lists.count > 0);
    old_chunk_list_gaps_offset, old_chunk_gaps_offset, old_flags_offset: s64;
    new_chunk_list_gaps_offset, new_chunk_gaps_offset, new_flags_offset: s64;

    old_alloc_size := chunk_lists.count - 1;
    assert(old_alloc_size >= 0);
    old_chunk_gaps_offset = old_alloc_size;
    // one added chunk list
    new_alloc_size := old_alloc_size + 1;
    new_chunk_gaps_offset = new_alloc_size;

    old_outer_chunk_count := 0;
    new_outer_chunk_count := 0;
    if chunk_lists.count == 1 {
        new_outer_chunk_count = chunk_lists[0].count;
    } else {
        for 0..chunk_lists.count-2 {
            old_outer_chunk_count += chunk_lists[it].count;
        }
        new_outer_chunk_count = old_outer_chunk_count + chunk_lists[chunk_lists.count-1].count;
    }
    // one gap tracking value per outer chunk. an outer chunk is a bundle of 64 divisions of the smallest allocation size.
    old_alloc_size += old_outer_chunk_count;
    new_alloc_size += new_outer_chunk_count;

    if old_alloc_size > 0 {
        // 8 byte align
        old_flags_offset = ceil_to_multiple(old_alloc_size, 8);
        old_alloc_size = old_flags_offset;
        // one 64 bit flag set per chunk
        old_flags_size := old_outer_chunk_count * 8;
        old_alloc_size += old_flags_size;
    }

    new_flags_offset = ceil_to_multiple(new_alloc_size, 8);
    new_alloc_size = new_flags_offset;
    new_flags_size := new_outer_chunk_count * 8;
    new_alloc_size += new_flags_size;

    assert(new_alloc_size > old_alloc_size);
    
    books_array_data_offset := new_alloc_size;
    new_books: Nesting_Allocator_Books;
    books_array_data_size := build_nesting_allocator_books(allocator, *new_books);
    new_alloc_size += books_array_data_size;

    new_alloc_size_mul2 := max(ceil_to_multiple(new_alloc_size, 2), 128);

    chunk_list_gaps_copy_size := old_chunk_gaps_offset;
    chunk_gaps_copy_size := old_flags_offset - old_chunk_gaps_offset;
    flags_copy_size := old_alloc_size - old_flags_offset;

    books_data: *u8;
    
    if new_alloc_size_mul2 > books_allocated_size {
        new_ptr := alloc(new_alloc_size_mul2);
        books_allocated_size = new_alloc_size_mul2;
        old_ptr := books.largest_gap_per_list.data;
        copy_old_data := old_ptr != null;
        if copy_old_data {
            assert(chunk_list_gaps_copy_size != 0 && chunk_gaps_copy_size != 0 && flags_copy_size != 0);
        } else {
            assert(chunk_list_gaps_copy_size == 0 && chunk_gaps_copy_size == 0 && flags_copy_size == 0);
        }
        if books.largest_gap_per_list.count > 0 {
            if copy_old_data {
                memcpy(new_ptr,                         old_ptr,                            chunk_list_gaps_copy_size);
                memcpy(new_ptr + new_chunk_gaps_offset, old_ptr + old_chunk_gaps_offset,    chunk_gaps_copy_size);
                memcpy(new_ptr + new_flags_offset,      old_ptr + old_flags_offset,         flags_copy_size);
                free(old_ptr);
            }
        }

        books_data = new_ptr;
    } else {
        books_data = books.largest_gap_per_list.data;
        books_dummy_array: []u8 = ---;
        books_dummy_array.data = books_data;
        books_dummy_array.count = new_alloc_size;
        copy_range_inside_array(books_dummy_array, new_chunk_gaps_offset, old_chunk_gaps_offset, chunk_gaps_copy_size);
        copy_range_inside_array(books_dummy_array, new_flags_offset, old_flags_offset, flags_copy_size);
    }

    copy_size := size_of([]u8) * new_books.gap_list_of_lists.count;
    memcpy(books_data + books_array_data_offset, new_books.gap_list_of_lists.data, copy_size);
    books_array_data_offset += copy_size;
    copy_size = size_of([]u64) * new_books.flag_list_of_lists.count;
    memcpy(books_data + books_array_data_offset, new_books.flag_list_of_lists.data, copy_size);

     {
        using new_books;
        largest_gap_per_list.data = books_data;
        for 0..chunk_lists.count-1 {
            gaps_offset := gap_list_of_lists[it].data.(u64);
            gap_list_of_lists[it].data = xx (books_data + gaps_offset);
            flags_offset := flag_list_of_lists[it].data.(u64);
            flag_list_of_lists[it].data = xx (books_data.(u64) + flags_offset);
        }
        largest_gap_per_list[largest_gap_per_list.count-1] = 64;
        list_1 := gap_list_of_lists[gap_list_of_lists.count-1];
        memset(list_1.data, 64, list_1.count);
        list_2 := flag_list_of_lists[flag_list_of_lists.count-1];
        memset(list_2.data, 0, list_2.count * size_of(u64));
    }

    books = new_books;
}

/*
Nesting_Allocator {
    books pointers:

    ----------- largest_gap_array_ptr    
    |     ----- lists_of_gaps_array_ptr 
    |     |     flag_set_array_ptr ---------------------------------------
    |     |                                                               |
    |     ------------------------------------------                      |
    v                                              V                      v
    [gaps data | lists_of_gaps data | flags data | [lists_of_gaps_ptrs] | [flags_ptrs]
                  ^    ^   ^   ^                    |  |   |   |           |   |  |  |
                  |    |   |   |--------------------   |   |   |           (point into the flags data. omitted arrows because diagram would get confusing)
                  |    |   |---------------------------|   |   |
                  |    |------------------------------------   |
                  |--------------------------------------------|

*/

#scope_file // ------------------------------------------------------------------------------------------------ { FILE }

did_small_chunk_count_warning := false;
