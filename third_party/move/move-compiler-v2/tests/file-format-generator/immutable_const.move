// Tests that #[immutable] on constants of any visibility causes the
// const$NAME accessor to carry both ConstantAccessor and Immutable.
module 0x42::immutable_const {
    // public immutable: accessor gets [const, immutable, persistent]
    #[immutable]
    public const MAX: u64 = 100;

    // package immutable: accessor gets [const, immutable]
    #[immutable]
    package const PKG_MAX: u64 = 50;

    // public non-immutable: accessor gets only [const, persistent]
    public const MIN: u64 = 0;
}
