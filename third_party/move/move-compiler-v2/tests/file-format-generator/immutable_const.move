// Tests that #[immutable] on a public constant causes the const$NAME accessor
// to carry both ConstantAccessor and Immutable. #[immutable] is only allowed
// on public constants (not package/private).
module 0x42::immutable_const {
    // public immutable: accessor gets [const, immutable, persistent]
    #[immutable]
    public const MAX: u64 = 100;

    // public non-immutable: accessor gets only [const, persistent]
    public const MIN: u64 = 0;

    // package non-immutable: accessor gets only [const]
    package const PKG_MAX: u64 = 50;
}
