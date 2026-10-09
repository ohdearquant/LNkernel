// Copyright (C) 2026 HaiyangLi
// SPDX-License-Identifier: Apache-2.0

use lion_core::{Capability, Kernel, KeyError, Right, Rights, SealedTag, SecurityLevel};

fn delegate_read_capability(kernel: &mut Kernel) -> Capability {
    kernel.register_plugin(1, SecurityLevel::Public, 0).unwrap();
    kernel.register_plugin(2, SecurityLevel::Public, 0).unwrap();

    // Keep the raw root away from the first allocated child ID.
    let root = Capability::new(
        100,
        1,
        42,
        Rights::from_slice(&[Right::Read, Right::Write]),
        None,
        kernel.state().kernel().key_epoch(),
        SealedTag::from_bytes([0; 32]),
    )
    .unwrap();
    kernel.insert_cap_raw(root, 1).unwrap();

    let child_id = kernel
        .delegate_cap(100, 2, Rights::singleton(Right::Read))
        .unwrap();
    assert_ne!(child_id, 100);
    assert!(kernel.plugin_holds(2, child_id));
    kernel.get_cap(child_id).unwrap().clone()
}

#[test]
fn with_key_rejects_zero_and_accepts_a_nonzero_last_byte() {
    assert!(matches!(Kernel::with_key([0; 32]), Err(KeyError)));

    let mut key = [0; 32];
    key[31] = 1;
    assert!(Kernel::with_key(key).is_ok());
}

#[test]
fn keyed_kernel_starts_with_the_same_empty_state() {
    let keyed = Kernel::with_key([17; 32]).unwrap();
    let default = Kernel::new();

    assert_eq!(keyed.time(), default.time());
    assert_eq!(keyed.plugin_count(), default.plugin_count());
    assert_eq!(keyed.actor_count(), default.actor_count());
    assert_eq!(keyed.resource_count(), default.resource_count());
    assert_eq!(keyed.workflow_count(), default.workflow_count());
    assert_eq!(keyed.state().kernel().revocation().cap_count(), 0);
    assert_eq!(keyed.state().kernel().next_cap_id(), 0);
    assert_eq!(keyed.state().kernel().key_epoch(), 0);
    assert!(keyed.state().kernel().key_state().previous().is_none());
    assert!(keyed
        .state()
        .kernel()
        .key_state()
        .previous_epoch()
        .is_none());
    assert_eq!(
        keyed.state().kernel().key_epoch(),
        default.state().kernel().key_epoch()
    );
}

#[test]
fn delegated_seal_is_bound_to_the_supplied_key() {
    let mut kernel = Kernel::with_key([17; 32]).unwrap();
    let child = delegate_read_capability(&mut kernel);
    let other_key = Kernel::with_key([34; 32]).unwrap();
    let default = Kernel::new();

    assert_eq!(child.rights(), &Rights::singleton(Right::Read));
    assert!(kernel.state().kernel().verify_cap_seal(&child));
    assert!(!other_key.state().kernel().verify_cap_seal(&child));
    assert!(!default.state().kernel().verify_cap_seal(&child));
}

#[test]
fn changing_one_right_without_resealing_is_rejected() {
    let mut kernel = Kernel::with_key([17; 32]).unwrap();
    let child = delegate_read_capability(&mut kernel);
    assert!(kernel.state().kernel().verify_cap_seal(&child));

    let mut changed_rights = child.rights().clone();
    assert!(changed_rights.insert(Right::Write));
    let tampered = Capability::new(
        child.id(),
        child.holder(),
        child.target(),
        changed_rights,
        child.parent(),
        child.epoch(),
        *child.signature(),
    )
    .unwrap();

    assert_eq!(tampered.signature(), child.signature());
    assert!(!kernel.state().kernel().verify_cap_seal(&tampered));
    assert!(kernel.state().kernel().verify_cap_seal(&child));
}
