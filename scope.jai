
scope_set_allocator :: (allocator: Allocator) #expand {
    _save_allocator := context.allocator;
    context.allocator = allocator;
    `defer context.allocator = _save_allocator;
}

scope_lock_mutex :: (mutex: *Mutex) #expand {
    lock(mutex);
    `defer unlock(mutex);
}

// a convenience proc for program startup systems, where if any of them fail, none of the
// rest will run. and, deinitialization is deferred at the same time.
// if you're familiar with c++, this is the ctor/dtor pattern, but for a static system.
// it's meant to be used like so:
// setup_success := true;
// scope_system_setup(System_1, *setup_success);
// scope_system_setup(System_2, *setup_success);
// ... and elsewhere...
// System_1 :: struct { 
//      scope_initialize :: () -> bool {}
//      scope_deinitialize :: () {}
// }
scope_system_setup :: ($T: Type, do_run: *bool) #expand {
    if !do_run.* then return;
    do_run.* = T.scope_initialize();
    if !do_run.* then return;
    `defer T.scope_deinitialize();
}

scope_set_working_directory :: (dir: string) #expand {
    cwd := get_working_directory();
    set_working_directory(dir);
    `defer set_working_directory(cwd);   
}

scope_mark_and_recede_allocations :: (using bump: *Bump_Allocator) #expand {
    mark := bump_allocator_get_high_water_mark(bump);
    `defer bump_allocator_reset_to_high_water_mark(bump, mark);
}

