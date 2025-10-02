// Core data types for CIP-0143 programmable tokens
// Migrated from SmartTokens.Types.PTokenDirectory and SmartTokens.Types.ProtocolParams

use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use aiken/builtin

/// Constants for token names
pub const origin_node_tn = #"00"

pub const node_key_tn_prefix = #"01"

/// Directory node in the linked list of registered programmable token policies
/// This represents an entry in the CIP-0143 registry
pub type DirectorySetNode {
  /// The key (currency symbol) of the programmable token policy
  key: ByteArray,
  /// The next key in lexicographical order (for linked list traversal)
  next: ByteArray,
  /// The transfer logic script credential that validates token transfers
  transfer_logic_script: Credential,
  /// The issuer logic script credential that handles minting/burning and seizure
  issuer_logic_script: Credential,
  /// Optional global state NFT currency symbol for this policy
  global_state_cs: ByteArray,
}

/// Blacklist node in the linked list of sanctioned addresses
/// Used for freeze-and-seize functionality
pub type BlacklistNode {
  /// The key (credential hash) of the blacklisted address
  key: ByteArray,
  /// The next key in lexicographical order
  next: ByteArray,
}

/// Protocol parameters stored on-chain
/// This is referenced by all programmable token transactions
pub type ProgrammableLogicGlobalParams {
  /// Currency symbol of the directory node NFTs
  directory_node_cs: PolicyId,
  /// The programmable logic base credential (payment credential for all programmable token UTxOs)
  prog_logic_cred: Credential,
}

/// Proof that a token is (or is not) in the directory
pub type TokenProof {
  /// Token exists in the directory at this reference input index
  TokenExists { node_idx: Int }
  /// Token does not exist (proof via covering node at this index)
  TokenDoesNotExist { node_idx: Int }
}

/// Proof of blacklist membership or non-membership
pub type BlacklistProof {
  /// Proof of non-membership via covering node
  NonmembershipProof { node_idx: Int }
}

/// Redeemer for the global programmable logic stake validator
pub type ProgrammableLogicGlobalRedeemer {
  /// Transfer action with proofs for each token type
  TransferAct { proofs: List<TokenProof> }
  /// Seize action to confiscate tokens from blacklisted address
  SeizeAct {
    seize_input_idx: Int,
    seize_output_idx: Int,
    directory_node_idx: Int,
  }
}

/// Action for the minting policy
pub type SmartTokenMintingAction {
  /// The credential of the minting logic script that must be invoked
  minting_logic_cred: Credential,
}

/// Redeemer for directory minting policy (linked list operations)
pub type DirectoryRedeemer {
  /// Initialize the directory with the origin node
  DirectoryInit
  /// Insert a new programmable token policy into the directory
  DirectoryInsert {
    key: ByteArray,
    hashed_param: ByteArray,
  }
}

/// Redeemer for blacklist minting policy (linked list operations)
pub type BlacklistRedeemer {
  /// Initialize the blacklist with the origin node
  BlacklistInit
  /// Insert a credential into the blacklist
  BlacklistInsert { key: ByteArray }
  /// Remove a credential from the blacklist
  BlacklistRemove { key: ByteArray }
}

/// Helper to create node key token name from a bytearray key
pub fn node_key_tn(key: ByteArray) -> ByteArray {
  builtin.append_bytearray(node_key_tn_prefix, key)
}
