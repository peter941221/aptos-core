// Tests that #[immutable] on non-public constants is rejected.
// Only public constants may carry #[immutable].
module 0x42::M {
    // Error: private constant
    #[immutable]
    const PRIV: u64 = 42;

    // Error: package constant can be downgraded to private on upgrade,
    // which conflicts with the Persistent constraint implied by #[immutable].
    #[immutable]
    package const PKG: u64 = 99;

    public fun use_it(): u64 { PRIV + PKG }
}
