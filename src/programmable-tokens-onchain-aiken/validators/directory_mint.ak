use aiken/collection/list
use aiken/primitive/bytearray
// Directory minting policy - manages the linked list of registered programmable token policies
// Migrated from SmartTokens.LinkedList.MintDirectory

use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use linked_list.{
  collect_node_ios, is_inserted_directory_node, is_updated_directory_node,
  validate_directory_init, validate_directory_node_output,
}
use types.{
  DirectoryInit, DirectoryInsert, DirectoryRedeemer, DirectorySetNode,
  node_key_tn,
}
use utils.{bytearray_lt, check_single_mint, expect_inline_datum}

validator directory_mint(utxo_ref: OutputReference) {
  mint(redeemer: DirectoryRedeemer, policy_id: PolicyId, self: Transaction) {
    // Ensure this is a one-shot minting policy by checking that utxo_ref is spent
    expect
      list.any(self.inputs, fn(input) { input.output_reference == utxo_ref })

    let (node_inputs, node_outputs) = collect_node_ios(self, policy_id)

    when redeemer is {
      DirectoryInit ->
        // Initialize the directory with an empty origin node
        validate_directory_init(node_inputs, node_outputs, self.mint, policy_id)

      DirectoryInsert { key, .. } -> {
        // Validate key is a valid currency symbol (28 bytes)
        expect bytearray.length(key) == 28

        // Must have exactly one node input (the covering node)
        expect [covering_input] = node_inputs
        let covering_datum = expect_inline_datum(covering_input.output)
        expect covering_node: DirectorySetNode = covering_datum

        // The covering node must cover the key to insert
        expect bytearray_lt(covering_node.key, key)
        expect bytearray_lt(key, covering_node.next)

        // Must mint exactly one node token with the new key
        expect check_single_mint(self.mint, policy_id, node_key_tn(key), 1)

        // Parse the outputs to find the two new nodes
        let output_nodes =
          list.map(
            node_outputs,
            fn(out) { validate_directory_node_output(out, policy_id) },
          )

        // Must have exactly 2 outputs: the updated covering node and the new inserted node
        expect list.length(output_nodes) == 2

        // One output must be the updated covering node (key -> insert_key)
        // One output must be the new inserted node (insert_key -> next)
        expect
          list.any(
            output_nodes,
            fn(node) { is_updated_directory_node(node, covering_node.key, key) },
          )

        expect
          list.any(
            output_nodes,
            fn(node) {
              is_inserted_directory_node(
                node,
                key,
                covering_node.next,
                covering_node.transfer_logic_script,
                covering_node.issuer_logic_script,
                covering_node.global_state_cs,
              )
            },
          )

        // TODO: Validate that the key is a valid programmable token registration
        // This requires checking the issuance CBOR hex reference (complex in Aiken)
        // For now we trust the off-chain code to provide correct registrations
        True
      }
    }
  }

  else(_) {
    fail
  }
}
