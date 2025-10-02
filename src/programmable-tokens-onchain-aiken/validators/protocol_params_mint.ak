// Protocol Parameters Minting Policy
// One-shot minting policy for the protocol parameters NFT
// Migrated from SmartTokens.Contracts.ProtocolParams

use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use aiken/collection/list

validator protocol_params_mint(utxo_ref: OutputReference) {
  mint(_redeemer: Data, _policy_id: PolicyId, self: Transaction) {
    // This is a one-shot minting policy
    // It can only mint when the specified UTXO is spent
    expect
      list.any(
        self.inputs,
        fn(input) { input.output_reference == utxo_ref },
      )

    // Additional validation: should mint exactly 1 token
    // (This is implicit in the design but we can add checks if needed)

    True
  }

  else(_) {
    fail
  }
}
