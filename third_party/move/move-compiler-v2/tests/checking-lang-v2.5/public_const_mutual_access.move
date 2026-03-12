// Tests that two modules cannot access each other's public constants (circular dependency)

module 0x42::M {
    use 0x42::N;

    public const A: u64 = 10;

    public fun use_n_const(): u64 {
        N::B
    }
}

module 0x42::N {
    use 0x42::M;

    public const B: u64 = 20;

    public fun use_m_const(): u64 {
        M::A
    }
}
