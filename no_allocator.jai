
no_allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    if mode == {
    case .CREATE_HEAP; #through;
    case .ALLOCATE;
        assert(false, "no_allocator is not supposed to allocate");
    case .RESIZE;
        if size <= old_size {
            return old_memory;
        }
        assert(false, "no_allocator is not supposed to allocate");
    case .IS_THIS_YOURS;
        assert(false, "no_allocator is not able to answer if an allocation belongs to it");
    case .FREE;
    case .DESTROY_HEAP;
    case .STARTUP;
    case .SHUTDOWN;
    case .THREAD_START;
    case .THREAD_STOP;
    };
    return null;
}

no_allocator := Allocator.{proc=no_allocator_proc};