// Copyright © Aptos Foundation
// SPDX-License-Identifier: Apache-2.0

// Tests that the compiler validates closure arguments against `access_of`
// declarations on callee parameters.

module 0x42::access_of_errors {
    struct Counter has key { value: u64 }
    struct Config  has key { active: bool }
    struct Balance has key { coins: u64 }

    // =========================================================================
    // Library: opaque closures
    // =========================================================================

    fun read_counter(addr: address): u64 acquires Counter {
        Counter[addr].value
    }
    spec read_counter {
        pragma opaque;
        ensures result == global<Counter>(addr).value;
        aborts_if !exists<Counter>(addr);
    }

    fun read_config(addr: address): bool acquires Config {
        Config[addr].active
    }
    spec read_config {
        pragma opaque;
        ensures result == global<Config>(addr).active;
        aborts_if !exists<Config>(addr);
    }

    fun write_counter(addr: address) acquires Counter {
        Counter[addr].value = Counter[addr].value + 1;
    }
    spec write_counter {
        pragma opaque;
        modifies global<Counter>(addr);
        ensures global<Counter>(addr).value == old(global<Counter>(addr).value) + 1;
        aborts_if !exists<Counter>(addr);
    }

    // =========================================================================
    // 1. access_of too narrow (reads): missing Config
    // =========================================================================

    fun apply_narrow_read(f: |address| u64, x: address): u64 {
        f(x)
    }
    spec apply_narrow_read {
        pragma opaque;
        access_of<f>(a: address) reads Counter;
        ensures ensures_of<f>(x, result);
        aborts_if aborts_of<f>(x);
    }

    fun test_narrow_read(addr: address): u64 acquires Counter, Config {
        apply_narrow_read(|a| { // error: function argument accesses resource
            if (Config[a].active) { Counter[a].value } else { 0 }
        } spec {
            ensures global<Config>(a).active ==> result == global<Counter>(a).value;
            ensures !global<Config>(a).active ==> result == 0;
        }, addr)
    }

    // =========================================================================
    // 2. access_of too narrow (writes): reads declared but closure writes
    // =========================================================================

    fun apply_reads_only(f: |address|, x: address) {
        f(x)
    }
    spec apply_reads_only {
        pragma opaque;
        access_of<f>(a: address) reads Counter;
        ensures ensures_of<f>(x);
        aborts_if aborts_of<f>(x);
    }

    fun test_writes_violation(addr: address) acquires Counter {
        apply_reads_only(|a| write_counter(a) spec { // error: function argument writes resource
            modifies global<Counter>(a);
            ensures global<Counter>(a).value == old(global<Counter>(a).value) + 1;
            aborts_if !exists<Counter>(a);
        }, addr);
    }

    // =========================================================================
    // 3. Parameter forwarding violation: wrapper's access_of exceeds callee's
    // =========================================================================

    fun apply_counter_only(f: |address| u64, x: address): u64 {
        f(x)
    }
    spec apply_counter_only {
        pragma opaque;
        access_of<f>(a: address) reads Counter;
        ensures ensures_of<f>(x, result);
        aborts_if aborts_of<f>(x);
    }

    fun wrapper(g: |address| u64, x: address): u64 {
        apply_counter_only(g, x) // error: function argument accesses resource
    }
    spec wrapper {
        pragma opaque;
        access_of<g>(a: address) reads Counter reads Config;
        ensures ensures_of<g>(x, result);
        aborts_if aborts_of<g>(x);
    }
}
