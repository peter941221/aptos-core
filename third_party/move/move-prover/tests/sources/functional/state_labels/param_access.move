// Copyright © Aptos Foundation
// SPDX-License-Identifier: Apache-2.0
// flag: --language-version=2.5-unstable

// Tests frame conditions derived from `access_of` declarations on function
// parameters.  The `access_of` annotation tells the prover which resources
// a function parameter may read or write, enabling frame condition inference
// for the parameter variant in the apply procedure.

module 0x42::param_access {
    struct Data  has key { value: u64 }
    struct Index has key { pos: u64 }

    // =========================================================================
    // Library
    // =========================================================================

    /// Opaque read-only function accessing both Data and Index.
    fun read_indexed(addr: address): u64 acquires Data, Index {
        Data[addr].value + Index[addr].pos
    }
    spec read_indexed {
        pragma opaque;
        pragma aborts_if_is_partial;
        ensures result == global<Data>(addr).value + global<Index>(addr).pos;
    }

    // =========================================================================
    // Higher-order wrapper with access_of (reads only)
    // =========================================================================

    fun apply_reads(f: |address| u64, x: address): u64 {
        f(x)
    }
    spec apply_reads {
        pragma opaque;
        pragma verify = false;
        access_of<f>(a: address) reads Data reads Index;
        ensures result == result_of<f>(x);
        ensures ensures_of<f>(x, result);
    }

    // =========================================================================
    // 1. Reads access_of — success
    // =========================================================================

    /// With access_of declaring reads-only, both resources are unchanged.
    fun test_reads_access_of(addr: address): u64 acquires Data, Index {
        apply_reads(|a| read_indexed(a) spec {
            ensures result == global<Data>(a).value + global<Index>(a).pos;
        }, addr)
    }
    spec test_reads_access_of {
        pragma aborts_if_is_partial;
        ensures result == global<Data>(addr).value + global<Index>(addr).pos;
        ensures global<Data>(addr) == old(global<Data>(addr));
        ensures global<Index>(addr) == old(global<Index>(addr));
    }

    // =========================================================================
    // 2. Reads access_of — failure
    // =========================================================================

    /// Wrong result claim.
    fun test_reads_access_of_wrong(addr: address): u64 acquires Data, Index {
        apply_reads(|a| read_indexed(a) spec {
            ensures result == global<Data>(a).value + global<Index>(a).pos;
        }, addr)
    }
    spec test_reads_access_of_wrong {
        pragma aborts_if_is_partial;
        ensures result == global<Data>(addr).value * global<Index>(addr).pos; // error: result is value + pos, not value * pos
    }

    // =========================================================================
    // 3. Writes access_of — parameter variant writes + returns post-state value
    // =========================================================================

    /// Opaque function that writes Data and returns the new value.
    fun set_data(addr: address, v: u64): u64 acquires Data {
        Data[addr].value = v;
        Data[addr].value
    }
    spec set_data {
        pragma opaque;
        modifies global<Data>(addr);
        ensures result == v;
        ensures global<Data>(addr).value == v;
        aborts_if !exists<Data>(addr);
    }

    fun apply_writes(f: |address| u64, x: address): u64 {
        f(x)
    }
    spec apply_writes {
        pragma opaque;
        pragma verify = false;
        modifies global<Data>(x);
        access_of<f>(a: address) writes Data;
        ensures ensures_of<f>(x, result);
        aborts_if aborts_of<f>(x);
    }

    /// Positive: parameter variant with writes, result comes from post-state.
    fun test_writes_access_of(addr: address): u64 acquires Data {
        apply_writes(|a| set_data(a, 99) spec {
            modifies global<Data>(a);
            ensures result == 99;
            ensures global<Data>(a).value == 99;
            aborts_if !exists<Data>(a);
        }, addr)
    }
    spec test_writes_access_of {
        aborts_if !exists<Data>(addr);
        ensures result == 99;
    }

    /// Negative: wrong result claim for writes parameter variant.
    fun test_writes_access_of_wrong(addr: address): u64 acquires Data {
        apply_writes(|a| set_data(a, 99) spec {
            modifies global<Data>(a);
            ensures result == 99;
            ensures global<Data>(a).value == 99;
            aborts_if !exists<Data>(a);
        }, addr)
    }
    spec test_writes_access_of_wrong {
        aborts_if !exists<Data>(addr);
        ensures result == 0; // error: post-condition does not hold
    }

    // =========================================================================
    // 4. Mixed read/write access_of — Config is read-only, Data is writable
    // =========================================================================

    struct Config has key { active: bool }

    fun apply_mixed(f: |address| u64, x: address): u64 {
        f(x)
    }
    spec apply_mixed {
        pragma opaque;
        pragma verify = false;
        modifies global<Data>(x);
        access_of<f>(a: address) reads Config writes Data;
        ensures ensures_of<f>(x, result);
        aborts_if aborts_of<f>(x);
    }

    /// Opaque function that writes Data conditionally on Config.
    fun conditional_set(addr: address): u64 acquires Data, Config {
        if (Config[addr].active) { Data[addr].value = 77 };
        Data[addr].value
    }
    spec conditional_set {
        pragma opaque;
        modifies global<Data>(addr);
        ensures global<Config>(addr).active ==> result == 77;
        ensures global<Config>(addr).active ==> global<Data>(addr).value == 77;
        aborts_if !exists<Data>(addr);
        aborts_if !exists<Config>(addr);
    }

    /// Positive: mixed access — Config unchanged (reads-only), result depends on Config.
    fun test_mixed_access_of(addr: address): u64 acquires Data, Config {
        apply_mixed(|a| conditional_set(a) spec {
            modifies global<Data>(a);
            ensures global<Config>(a).active ==> result == 77;
            ensures global<Config>(a).active ==> global<Data>(a).value == 77;
            aborts_if !exists<Data>(a);
            aborts_if !exists<Config>(a);
        }, addr)
    }
    spec test_mixed_access_of {
        aborts_if !exists<Data>(addr);
        aborts_if !exists<Config>(addr);
        ensures global<Config>(addr).active ==> result == 77;
        ensures global<Config>(addr) == old(global<Config>(addr));
    }
}
