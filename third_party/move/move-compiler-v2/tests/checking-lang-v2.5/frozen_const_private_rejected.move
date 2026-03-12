// Tests that #[frozen] on non-public constants is rejected.
// Only public constants may carry #[frozen].
module 0x42::M {
    // Error: private constant
    #[frozen]
    const PRIV: u64 = 42;

    // Error: package constant can be downgraded to private on upgrade,
    // which conflicts with the Persistent constraint implied by #[frozen].
    #[frozen]
    package const PKG: u64 = 99;

    public fun use_it(): u64 { PRIV + PKG }
}
