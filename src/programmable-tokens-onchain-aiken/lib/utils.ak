// Utility functions for CIP-0143 validators
// Migrated from various Plutarch utility modules

use cardano/address.{Credential}
use cardano/assets.{AssetName, PolicyId, Value, flatten, quantity_of, tokens, zero, add, ada_policy_id}
use cardano/transaction.{
  InlineDatum, Input, Output, Transaction,
}
use aiken/collection/list
use aiken/collection/dict
use aiken/builtin

/// Check if a value contains at least the required amount of a specific asset
pub fn value_contains(value: Value, required: Value) -> Bool {
  list.all(
    flatten(required),
    fn(asset) {
      let (policy, name, req_qty) = asset
      quantity_of(value, policy, name) >= req_qty
    },
  )
}

/// Get the datum from an output, expecting an inline datum
pub fn expect_inline_datum(output: Output) -> Data {
  when output.datum is {
    InlineDatum(d) -> d
    _ -> fail @"Expected inline datum"
  }
}

/// Find an input by a predicate
pub fn find_input(
  inputs: List<Input>,
  predicate: fn(Input) -> Bool,
) -> Option<Input> {
  list.find(inputs, predicate)
}

/// Must find an input by predicate (fails if not found)
pub fn must_find_input(
  inputs: List<Input>,
  predicate: fn(Input) -> Bool,
) -> Input {
  when find_input(inputs, predicate) is {
    Some(input) -> input
    None -> fail @"Required input not found"
  }
}

/// Check if a currency symbol is present in a value
pub fn has_currency_symbol(value: Value, cs: PolicyId) -> Bool {
  dict.size(tokens(value, cs)) > 0
}

/// Count unique tokens in a value (number of distinct currency symbol + token name pairs)
pub fn count_unique_tokens(value: Value) -> Int {
  flatten(value) |> list.length
}

/// Check if exactly one token with a specific token name is minted/burned
pub fn check_single_mint(
  mint: Value,
  cs: PolicyId,
  tn: AssetName,
  expected_amount: Int,
) -> Bool {
  let minted = quantity_of(mint, cs, tn)
  let policy_tokens = tokens(mint, cs)

  // Must mint exactly the expected amount and no other tokens from this policy
  minted == expected_amount && dict.size(policy_tokens) == 1
}

/// Filter a value to only contain tokens from a specific currency symbol
pub fn filter_by_currency_symbol(value: Value, cs: PolicyId) -> Value {
  let policy_tokens = tokens(value, cs)
  dict.foldl(
    policy_tokens,
    zero,
    fn(tn, qty, acc) { add(acc, cs, tn, qty) },
  )
}

/// Strip Ada from a value, keeping only native tokens
pub fn strip_ada(value: Value) -> Value {
  let all_assets = flatten(value)
  list.foldl(
    all_assets,
    zero,
    fn(asset, acc) {
      let (policy, name, qty) = asset
      if policy == ada_policy_id {
        acc
      } else {
        add(acc, policy, name, qty)
      }
    },
  )
}

/// Get all outputs paying to a specific credential
pub fn outputs_at_credential(
  outputs: List<Output>,
  cred: Credential,
) -> List<Output> {
  list.filter(
    outputs,
    fn(output) { output.address.payment_credential == cred },
  )
}

/// Get all inputs spending from a specific credential
pub fn inputs_from_credential(
  inputs: List<Input>,
  cred: Credential,
) -> List<Input> {
  list.filter(
    inputs,
    fn(input) { input.output.address.payment_credential == cred },
  )
}

/// Count inputs from a specific credential
pub fn count_inputs_from_credential(
  inputs: List<Input>,
  cred: Credential,
) -> Int {
  inputs_from_credential(inputs, cred) |> list.length
}

/// Check if a transaction is signed by a public key hash
pub fn is_signed_by(tx: Transaction, pkh: ByteArray) -> Bool {
  list.any(tx.extra_signatories, fn(sig) { sig == pkh })
}

/// Check if a script is invoked (via withdrawal)
pub fn is_script_invoked(tx: Transaction, script_cred: Credential) -> Bool {
  list.any(
    tx.withdrawals,
    fn(withdrawal) {
      let Pair(cred, _amount) = withdrawal
      cred == script_cred
    },
  )
}

/// Get element at index from a list
pub fn elem_at(lst: List<a>, idx: Int) -> a {
  when list.drop(lst, idx) is {
    [elem, ..] -> elem
    [] -> fail @"Index out of bounds"
  }
}

/// Check if a bytearray is lexicographically less than another
pub fn bytearray_lt(a: ByteArray, b: ByteArray) -> Bool {
  builtin.less_than_bytearray(a, b)
}
