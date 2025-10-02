use aiken/collection/list
// Programmable Token Issuance Minting Policy
// This policy handles minting and burning of registered programmable tokens
// Migrated from SmartTokens.Contracts.Issuance

use cardano/address.{Credential}
use cardano/assets.{PolicyId, flatten, quantity_of}
use cardano/transaction.{Output, Transaction}
use types.{SmartTokenMintingAction}

validator issuance_mint(
  programmable_logic_base: Credential,
  minting_logic_cred: Credential,
) {
  mint(
    redeemer: SmartTokenMintingAction,
    own_policy: PolicyId,
    self: Transaction,
  ) {
    // Validate that the redeemer matches the minting logic credential
    expect redeemer.minting_logic_cred == minting_logic_cred

    // Check that the minting logic script is invoked
    let invoked_scripts =
      list.map(
        self.withdrawals,
        fn(wdrl) {
          let Pair(cred, _amount) = wdrl
          cred
        },
      )

    expect list.has(invoked_scripts, minting_logic_cred)

    // Get the minted/burned amount for this policy
    let own_tokens = flatten(self.mint)
    let tokens_for_policy =
      list.filter(
        own_tokens,
        fn(token) {
          let (cs, _tn, _qty) = token
          cs == own_policy
        },
      )

    // For POC, we only allow one token name per policy
    expect list.length(tokens_for_policy) == 1

    expect [(_cs, tn, qty)] = tokens_for_policy

    if qty > 0 {
      // Minting tokens
      // First output must receive the minted tokens at programmable_logic_base
      expect [first_output, ..] = self.outputs

      expect first_output.address.payment_credential == programmable_logic_base

      expect quantity_of(first_output.value, own_policy, tn) == qty

      True
    } else if qty < 0 {
      // Burning tokens - no additional checks needed beyond the minting logic being invoked
      True
    } else {
      // Zero minting is not allowed
      fail @"Cannot mint zero tokens"
    }
  }

  else(_) {
    fail
  }
}
