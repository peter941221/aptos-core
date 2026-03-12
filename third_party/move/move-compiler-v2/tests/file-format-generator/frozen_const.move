// Tests that #[frozen] on a public constant causes the const$NAME accessor
// to carry both ConstantAccessor and Immutable. #[frozen] is only allowed
// on public constants (not package/private).
module 0x42::frozen_const {
    // public frozen: accessor gets [const, immutable, persistent]
    #[frozen]
    public const MAX: u64 = 100;

    // public non-frozen: accessor gets only [const, persistent]
    public const MIN: u64 = 0;

    // package non-frozen: accessor gets only [const]
    package const PKG_MAX: u64 = 50;
}
