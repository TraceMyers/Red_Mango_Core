
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
// example:
// setup_success := true;
// scope_setup(setup_system_a, teardown_system_a, *setup_success);
// scope_setup(setup_system_b, teardown_system_b, *setup_success);
// ...
scope_setup :: ($init_proc: ()->bool, $deinit_proc: (), continue_setup: *bool) #expand {
    if !continue_setup.* then return;
    #if init_proc {
        continue_setup.* = init_proc();
    } else {
        continue_setup.* = true;
    }
    if !continue_setup.* then return;
    #if deinit_proc then `defer deinit_proc();
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


