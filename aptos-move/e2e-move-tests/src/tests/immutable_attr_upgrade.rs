// Copyright (c) Aptos Foundation
// Licensed pursuant to the Innovation-Enabling Source Code License, available at https://github.com/aptos-labs/aptos-core/blob/main/LICENSE

//! E2E upgrade tests for `#[immutable]` on public constants.

use crate::{assert_success, assert_vm_status, MoveHarness};
use aptos_framework::BuildOptions;
use aptos_language_e2e_tests::account::Account;
use aptos_package_builder::PackageBuilder;
use aptos_types::{account_address::AccountAddress, transaction::TransactionStatus};
use move_core_types::vm_status::StatusCode;

fn publish(h: &mut MoveHarness, account: &Account, source: &str) -> TransactionStatus {
    let mut builder = PackageBuilder::new("Package");
    builder.add_source("m.move", source);
    let path = builder.write_to_temp().unwrap();
    h.publish_package_with_options(
        account,
        path.path(),
        BuildOptions::move_2().set_latest_language(),
    )
}

// ---------------------------------------------------------------------------
// #[immutable] on public constants (const$NAME accessor)
// ---------------------------------------------------------------------------

/// Upgrading an `#[immutable]` public constant with the same value is allowed.
#[test]
fn immutable_const_same_value_ok() {
    let mut h = MoveHarness::new();
    let acc = h.new_account_at(AccountAddress::from_hex_literal("0x910").unwrap());

    assert_success!(publish(
        &mut h,
        &acc,
        r#"
        module 0x910::m {
            #[immutable]
            public const VALUE: u64 = 42;
        }
    "#,
    ));

    // Re-publishing with identical value is compatible.
    assert_success!(publish(
        &mut h,
        &acc,
        r#"
        module 0x910::m {
            #[immutable]
            public const VALUE: u64 = 42;
        }
    "#,
    ));
}

/// Changing the value of an `#[immutable]` public constant is rejected,
/// because it changes the body of the `const$VALUE` accessor function.
#[test]
fn immutable_const_value_changed_rejected() {
    let mut h = MoveHarness::new();
    let acc = h.new_account_at(AccountAddress::from_hex_literal("0x911").unwrap());

    assert_success!(publish(
        &mut h,
        &acc,
        r#"
        module 0x911::m {
            #[immutable]
            public const VALUE: u64 = 42;
        }
    "#,
    ));

    // Changed value → const$VALUE body differs → incompatible.
    assert_vm_status!(
        publish(
            &mut h,
            &acc,
            r#"
            module 0x911::m {
                #[immutable]
                public const VALUE: u64 = 99;
            }
        "#,
        ),
        StatusCode::BACKWARD_INCOMPATIBLE_MODULE_UPDATE
    );
}

/// Removing `#[immutable]` from a public constant is rejected
/// (the Immutable attribute cannot be removed from the const$NAME accessor).
#[test]
fn immutable_const_attribute_removed_rejected() {
    let mut h = MoveHarness::new();
    let acc = h.new_account_at(AccountAddress::from_hex_literal("0x912").unwrap());

    assert_success!(publish(
        &mut h,
        &acc,
        r#"
        module 0x912::m {
            #[immutable]
            public const VALUE: u64 = 42;
        }
    "#,
    ));

    // Dropping #[immutable] removes Immutable from the accessor — incompatible.
    assert_vm_status!(
        publish(
            &mut h,
            &acc,
            r#"
            module 0x912::m {
                public const VALUE: u64 = 42;
            }
        "#,
        ),
        StatusCode::BACKWARD_INCOMPATIBLE_MODULE_UPDATE
    );
}

/// Adding `#[immutable]` to a previously non-immutable public constant is allowed.
#[test]
fn immutable_const_add_attribute_ok() {
    let mut h = MoveHarness::new();
    let acc = h.new_account_at(AccountAddress::from_hex_literal("0x913").unwrap());

    assert_success!(publish(
        &mut h,
        &acc,
        r#"
        module 0x913::m {
            public const VALUE: u64 = 42;
        }
    "#,
    ));

    // Adding #[immutable] with the same value is compatible.
    assert_success!(publish(
        &mut h,
        &acc,
        r#"
        module 0x913::m {
            #[immutable]
            public const VALUE: u64 = 42;
        }
    "#,
    ));
}

/// Without `#[immutable]`, changing a public constant's value is allowed.
#[test]
fn non_immutable_const_value_change_ok() {
    let mut h = MoveHarness::new();
    let acc = h.new_account_at(AccountAddress::from_hex_literal("0x914").unwrap());

    assert_success!(publish(
        &mut h,
        &acc,
        r#"
        module 0x914::m {
            public const VALUE: u64 = 1;
        }
    "#,
    ));

    // No #[immutable] → value change is compatible.
    assert_success!(publish(
        &mut h,
        &acc,
        r#"
        module 0x914::m {
            public const VALUE: u64 = 999;
        }
    "#,
    ));
}
