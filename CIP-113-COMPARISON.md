# CIP-113 vs Current Aiken Implementation - Comprehensive Comparison Report

## Executive Summary

The current Aiken implementation is based on **CIP-143** (which has been superseded by CIP-113). While CIP-113 reuses some components from CIP-143, there are **significant differences** in architecture, data structures, and validator logic. The current implementation **does NOT fully comply** with CIP-113.

---

## 1. TERMINOLOGY & NAMING DIFFERENCES

| CIP-113 Term | Current Aiken Implementation | Status |
|--------------|------------------------------|--------|
| `tokenRegistry` | `directory` (directory_mint.ak, directory_spend.ak) | ❌ **Different Name** |
| `registryNode` | `DirectorySetNode` | ❌ **Different Name** |
| `registrySpendScript` | `directory_spend` | ❌ **Different Name** |
| `registryMintingPolicy` | `directory_mint` | ❌ **Different Name** |
| `programmableLogicBase` | `programmable_logic_base` | ✅ **Same Concept** |
| `transferLogicScript` | `transfer_logic_script` (in DirectorySetNode) | ✅ **Same Concept** |
| `thirdPartyTransferLogicScript` | **MISSING** | ❌ **NOT IMPLEMENTED** |
| `issuancePolicy` | `issuance_mint` | ✅ **Same Concept** |
| `issuanceLogicScript` | `minting_logic_cred` (in issuance_mint.ak) | ⚠️ **Similar but Different** |
| `globalState` | `global_state_cs` (in DirectorySetNode) | ⚠️ **Partial Implementation** |
| `userStateManagerHash` | **MISSING** | ❌ **NOT IMPLEMENTED** |

---

## 2. DATA STRUCTURE COMPARISON

### 2.1 Registry/Directory Node Datum

**CIP-113 `RegistryNode`:**
```typescript
type RegistryNode {
    tokenPolicy: ByteArray,                      // 28 bytes
    nextTokenPolicy: ByteArray,                  // 28 bytes
    transferLogicScript: ByteArray,              // 28 bytes (hash)
    userStateManagerHash: ByteArray,             // 0 or 28 bytes
    globalStateUnit: ByteArray,                  // 0 or 28-60 bytes (policy + optional token name)
    thirdPartyTransferLogicScript: ByteArray     // 0 or 28 bytes
}
```

**Current Aiken `DirectorySetNode`:**
```aiken
pub type DirectorySetNode {
  key: ByteArray,                        // 28 bytes (tokenPolicy)
  next: ByteArray,                       // 28 bytes (nextTokenPolicy)
  transfer_logic_script: Credential,     // Full Credential (not just hash)
  issuer_logic_script: Credential,       // Full Credential (not in CIP-113)
  global_state_cs: ByteArray,            // 0 or 28 bytes (only policy, no token name)
}
```

**Differences:**

| Field | CIP-113 | Aiken | Issue |
|-------|---------|-------|-------|
| Token policy | `tokenPolicy: ByteArray` | `key: ByteArray` | ✅ Equivalent |
| Next policy | `nextTokenPolicy: ByteArray` | `next: ByteArray` | ✅ Equivalent |
| Transfer logic | `transferLogicScript: ByteArray` (28-byte hash) | `transfer_logic_script: Credential` | ❌ **Type mismatch**: CIP-113 stores hash, Aiken stores full Credential |
| User state manager | `userStateManagerHash: ByteArray` | **MISSING** | ❌ **NOT IMPLEMENTED** |
| Global state | `globalStateUnit: ByteArray` (28-60 bytes, includes token name) | `global_state_cs: ByteArray` (0-28 bytes, policy only) | ❌ **Incomplete**: Missing token name capability |
| Third party transfer | `thirdPartyTransferLogicScript: ByteArray` | **MISSING** | ❌ **NOT IMPLEMENTED** |
| Issuer logic | **NOT IN CIP-113** | `issuer_logic_script: Credential` | ⚠️ **Extra field**: From CIP-143, not in CIP-113 |

---

### 2.2 Transfer Redeemer

**CIP-113:**
```typescript
type TransferRedeemer {
    Transfer {
        registryNodes: List<Int>  // Indices of registry nodes in reference inputs
    }
    ThirdParty {
        registryNodes: List<Int>  // For admin actions
    }
}
```

**Current Aiken:**
```aiken
pub type ProgrammableLogicGlobalRedeemer {
  TransferAct { proofs: List<TokenProof> }
  SeizeAct {
    seize_input_idx: Int,
    seize_output_idx: Int,
    directory_node_idx: Int,
  }
}

pub type TokenProof {
  TokenExists { node_idx: Int }
  TokenDoesNotExist { node_idx: Int }
}
```

**Differences:**

| CIP-113 | Aiken | Issue |
|---------|-------|-------|
| `Transfer { registryNodes: List<Int> }` | `TransferAct { proofs: List<TokenProof> }` | ❌ **Different structure**: CIP-113 uses simple list of indices, Aiken uses TokenExists/TokenDoesNotExist proofs |
| `ThirdParty { registryNodes: List<Int> }` | **MISSING** | ❌ **NOT IMPLEMENTED**: No admin/third-party transfer capability |
| **N/A** | `SeizeAct { ... }` | ⚠️ **Extra constructor**: From CIP-143, likely covers admin actions but different structure |

---

## 3. VALIDATOR COMPARISON

### 3.1 Registry/Directory Validators

| Validator | CIP-113 | Aiken Implementation | Status |
|-----------|---------|----------------------|--------|
| Registry Spend Script | `registrySpendScript` | `directory_spend.ak` | ✅ Exists |
| Registry Minting Policy | `registryMintingPolicy` | `directory_mint.ak` | ✅ Exists |

**Registration Requirements Comparison:**

| Requirement | CIP-113 | Aiken | Status |
|-------------|---------|-------|--------|
| Previous node must be spent | ✅ Required | ✅ Implemented (`directory_mint.ak:84`) | ✅ |
| Update prev node's `nextTokenPolicy` | ✅ Required | ✅ Implemented (via `is_updated_directory_node`) | ✅ |
| Include registration certificate | ✅ Required | ❌ **NOT CHECKED** | ❌ **MISSING** |
| New node with proper datum fields | ✅ Required | ✅ Implemented | ✅ |
| Minimum lovelace | ✅ Should have minimum | ❌ **NOT CHECKED** | ❌ **MISSING** |
| Mint NFT with policy as token name | ✅ Required | ✅ Implemented (`directory_mint.ak:89`) | ✅ |
| No reference scripts on outputs | ✅ Must not have | ❌ **NOT CHECKED** | ❌ **MISSING** |
| Only payment credentials (no stake) | ✅ Must have only payment | ❌ **NOT CHECKED** | ❌ **MISSING** |
| issuancePolicy validation | ✅ Must be official instance | ✅ Implemented (via `is_programmable_token_registration`) | ✅ |

### 3.2 Programmable Logic Base

**CIP-113:**
- The spec mentions `programmableLogicBase` as "the unique Spend script that always holds all existing programmable tokens"
- **No explicit validation logic provided in spec** (marked as TODO)

**Current Aiken (`programmable_logic_base.ak`):**
- Implemented as a simple forwarding validator
- Checks that `programmable_logic_global` stake script is invoked
- **EXISTS and IMPLEMENTED**

**Status:** ✅ **Implemented** (CIP-113 spec incomplete on this)

---

### 3.3 Programmable Logic Global

**CIP-113:**
- Not explicitly defined in the specification
- Transfer validation logic is TODO

**Current Aiken (`programmable_logic_global.ak`):**
- Fully implemented stake validator
- Handles `TransferAct` and `SeizeAct`
- Validates token conservation, directory membership, and transfer logic invocation

**Status:** ✅ **Implemented** (extends beyond CIP-113 spec)

---

### 3.4 Issuance Policy

| Aspect | CIP-113 | Aiken | Status |
|--------|---------|-------|--------|
| Parameterized by issuance logic | ✅ Required | ✅ Implemented (parameterized by `programmable_logic_base` and `minting_logic_cred`) | ⚠️ **Different parameters** |
| Minted tokens sent to programmableLogicBase | ✅ Required | ✅ Implemented (`issuance_mint.ak:50`) | ✅ |
| Minting logic script invoked | ✅ Required | ✅ Implemented (`issuance_mint.ak:73`) | ✅ |

**Difference:** Aiken's `issuance_mint` takes TWO parameters (`programmable_logic_base`, `minting_logic_cred`), while CIP-113 specifies only `issuanceLogicScript` parameter.

---

## 4. MISSING FEATURES (In Aiken, Required by CIP-113)

### 4.1 **Third-Party Transfer Logic (Admin Actions)**

**CIP-113 Requirement:**
- `thirdPartyTransferLogicScript` field in RegistryNode
- `ThirdParty` constructor in TransferRedeemer
- Allows admins to execute privileged actions without user permission

**Aiken Implementation:**
- ❌ **NOT IMPLEMENTED**
- No field in `DirectorySetNode`
- No redeemer constructor
- `SeizeAct` might partially cover this, but structure is completely different

**Impact:** HIGH - Core feature for admin/issuer control missing

---

### 4.2 **User State Manager**

**CIP-113 Requirement:**
- `userStateManagerHash` field in RegistryNode (0 or 28 bytes)
- Optional per-user state management
- When present, reference inputs MUST be included depending on sub-standard

**Aiken Implementation:**
- ❌ **NOT IMPLEMENTED**
- No field in `DirectorySetNode`
- No validation logic for user state

**Impact:** MEDIUM - Limits state management flexibility for tokens

---

### 4.3 **Global State Unit (Full Support)**

**CIP-113 Requirement:**
- `globalStateUnit` is 0 or 28-60 bytes
- **Must include token name** (not just policy)
- Represents concatenation of policy (28 bytes) + token name (0-32 bytes)

**Aiken Implementation:**
- ⚠️ **PARTIAL**: `global_state_cs` only stores policy (28 bytes)
- ❌ **MISSING**: Cannot specify token name
- ❌ **MISSING**: Length validation for 28-60 bytes range

**Impact:** MEDIUM - Limits flexibility in global state identification

---

### 4.4 **Registration Validation Checks**

**CIP-113 Requirements (Missing in Aiken):**

1. ❌ **Registration certificate validation**
   - CIP-113: "The transaction MUST include the registration certificate of `transferLogicScript`"
   - Aiken: No check for certificate in `directory_mint.ak`
   - **Impact:** HIGH - Security requirement not enforced

2. ❌ **Minimum lovelace check**
   - CIP-113: "The new registryNode SHOULD have the minimum amount of lovelaces that the protocol allows"
   - Aiken: No validation
   - **Impact:** LOW - Best practice, not critical

3. ❌ **Reference script prohibition**
   - CIP-113: "Both the outputs MUST NOT have any reference script"
   - Aiken: No validation
   - **Impact:** MEDIUM - Could allow unintended behavior

4. ❌ **Stake credential prohibition**
   - CIP-113: "Both the outputs address MUST **only** have payment credentials"
   - Aiken: No validation (allows stake credentials)
   - **Impact:** MEDIUM - Deviates from spec

---

## 5. EXTRA FEATURES (In Aiken, Not in CIP-113)

### 5.1 **Issuer Logic Script in Registry**

**Aiken Implementation:**
- `DirectorySetNode` has `issuer_logic_script: Credential` field
- Used for seizure operations (`SeizeAct`)

**CIP-113:**
- Not present in RegistryNode
- Issuer logic is separate (part of issuance flow, not registry)

**Analysis:** This is from CIP-143. CIP-113 might handle issuer logic differently (not fully specified).

---

### 5.2 **Blacklist System**

**Aiken Implementation:**
- Full blacklist linked list system (`blacklist_mint.ak`)
- `BlacklistNode` type
- `BlacklistProof` for non-membership proofs
- Used in freeze-and-seize functionality

**CIP-113:**
- Not mentioned at all in the specification

**Analysis:** This is a CIP-143 feature for regulated tokens. Not part of CIP-113 base spec.

---

### 5.3 **Protocol Parameters UTxO**

**Aiken Implementation:**
- `ProgrammableLogicGlobalParams` stored in dedicated UTxO
- Contains `directory_node_cs` and `prog_logic_cred`
- Referenced by all transactions

**CIP-113:**
- Not explicitly defined
- The spec assumes fixed addresses but doesn't specify a params UTxO

**Analysis:** Implementation detail, likely acceptable extension.

---

### 5.4 **IssuanceCborHex System**

**Aiken Implementation:**
- `IssuanceCborHex` type storing prefix/postfix CBOR
- `issuance_cbor_hex_mint.ak` one-shot minting policy
- Used to validate parametrized policy computation

**CIP-113:**
- Not mentioned

**Analysis:** Implementation mechanism for validating issuance policies. Likely acceptable.

---

### 5.5 **TokenDoesNotExist Proof**

**Aiken Implementation:**
- `TokenProof` has both `TokenExists` and `TokenDoesNotExist`
- Allows proving a token is NOT programmable

**CIP-113:**
- Only mentions `registryNodes: List<Int>` (indices)
- Doesn't explicitly handle non-programmable tokens in transfer redeemer

**Analysis:** Useful extension, allows mixed transactions with programmable and non-programmable tokens.

---

## 6. ARCHITECTURAL DIFFERENCES

### 6.1 Credential Storage

| Aspect | CIP-113 | Aiken | Issue |
|--------|---------|-------|-------|
| Transfer logic storage | `ByteArray` (28-byte hash) | `Credential` (full struct with constructor) | ❌ **Incompatible on-chain representation** |
| Why it matters | Smaller datum, more efficient | More type-safe off-chain | **Different serialization** |

**Impact:** HIGH - Datums are not compatible between implementations

---

### 6.2 Redeemer Structure

**CIP-113:**
```typescript
Transfer { registryNodes: List<Int> }
```
- Simple list of indices
- One index per token policy in value (lexicographic order)
- Both programmable and non-programmable

**Aiken:**
```aiken
TransferAct { proofs: List<TokenProof> }
// where TokenProof = TokenExists {node_idx} | TokenDoesNotExist {node_idx}
```
- Explicit proof type
- Differentiates programmable from non-programmable
- More verbose

**Impact:** HIGH - Completely different redeemer structure, not compatible

---

## 7. SUMMARY TABLE

### 7.1 Missing CIP-113 Features

| Feature | Priority | Impact |
|---------|----------|--------|
| Third-party transfer logic field | HIGH | Cannot implement admin actions per CIP-113 |
| `ThirdParty` redeemer constructor | HIGH | Cannot execute admin transfers |
| User state manager field | MEDIUM | Limits state management options |
| Global state with token name | MEDIUM | Less flexible global state |
| Registration certificate check | HIGH | Security validation missing |
| Reference script prohibition check | MEDIUM | Spec compliance |
| Stake credential prohibition check | MEDIUM | Spec compliance |
| Credential as ByteArray (hash only) | HIGH | Datum incompatibility |
| Simple index list redeemer | HIGH | Redeemer incompatibility |

### 7.2 Extra Aiken Features (Not in CIP-113)

| Feature | From | Status |
|---------|------|--------|
| Issuer logic in registry | CIP-143 | Useful for freeze-and-seize |
| Blacklist system | CIP-143 | Useful for regulated tokens |
| Protocol params UTxO | Implementation | Reasonable extension |
| IssuanceCborHex system | Implementation | Validation mechanism |
| TokenDoesNotExist proof | Enhancement | Useful feature |
| SeizeAct redeemer | CIP-143 | Admin action mechanism (different from CIP-113) |

---

## 8. COMPATIBILITY ASSESSMENT

### Current Aiken Implementation is:

❌ **NOT COMPATIBLE** with CIP-113

**Reasons:**
1. **Data structure incompatibility**: RegistryNode fields don't match DirectorySetNode
2. **Missing required fields**: `thirdPartyTransferLogicScript`, `userStateManagerHash`
3. **Type mismatches**: Credentials stored as full Credential vs ByteArray hash
4. **Redeemer incompatibility**: Different transfer redeemer structure
5. **Missing validation checks**: Registration certificates, reference scripts, stake credentials

---

## 9. MIGRATION PATH (IF DESIRED)

To make the Aiken implementation CIP-113 compliant, you would need to:

### Phase 1: Data Structure Changes (BREAKING)
1. ✅ Rename `DirectorySetNode` → `RegistryNode`
2. ✅ Change `transfer_logic_script: Credential` → `transferLogicScript: ByteArray`
3. ✅ Add `userStateManagerHash: ByteArray` field
4. ✅ Change `global_state_cs: ByteArray` → `globalStateUnit: ByteArray` (support 28-60 bytes)
5. ✅ Add `thirdPartyTransferLogicScript: ByteArray` field
6. ⚠️ Remove or deprecate `issuer_logic_script` (not in CIP-113)

### Phase 2: Redeemer Changes (BREAKING)
1. ✅ Change `TransferAct { proofs: List<TokenProof> }` → `Transfer { registryNodes: List<Int> }`
2. ✅ Add `ThirdParty { registryNodes: List<Int> }` constructor
3. ⚠️ Remove or adapt `SeizeAct` to use `ThirdParty` pattern

### Phase 3: Validation Logic
1. ✅ Add registration certificate check in `directory_mint`
2. ✅ Add reference script prohibition check
3. ✅ Add stake credential prohibition check
4. ✅ Add minimum lovelace check
5. ✅ Update transfer validation to handle new redeemer structure

### Phase 4: Optional Extensions
1. ⚠️ Keep blacklist system as optional sub-standard
2. ⚠️ Keep protocol params UTxO as implementation detail
3. ⚠️ Keep IssuanceCborHex as validation mechanism

---

## 10. RECOMMENDATION

**Current Status:** The Aiken implementation is a **CIP-143-based system** that predates CIP-113.

**Options:**

### Option A: **Stick with CIP-143/Current Implementation**
- ✅ Already working and tested
- ✅ Includes useful features (blacklist, seizure)
- ✅ More type-safe with Credential types
- ❌ Not CIP-113 compliant
- ❌ May not interoperate with future CIP-113 wallets/dApps

### Option B: **Migrate to CIP-113**
- ✅ Future-proof and standard-compliant
- ✅ Will interoperate with CIP-113 ecosystem
- ✅ Simpler registry structure (hash-only storage)
- ❌ Requires breaking changes
- ❌ Lose some CIP-143 features (unless added as sub-standard)
- ❌ CIP-113 spec is incomplete (transfer validation TODO)

### Option C: **Hybrid Approach**
- Create CIP-113 compliant mode alongside current implementation
- Support both as different "sub-standards"
- Allows gradual migration

---

**Final Recommendation:** If this is a production system, **Option A** (stick with current) is safer until CIP-113 is finalized and has wider adoption. If this is new development aiming for future compatibility, **Option B** (migrate) would be better long-term.

---

## References

- **CIP-113 Specification**: https://github.com/HarmonicLabs/CIPs/tree/master/CIP-0113
- **CIP-143 Implementation**: Current Aiken codebase at `/Users/giovanni/Development/workspace/wsc-poc/src/programmable-tokens-onchain-aiken`
- **CPS-0003**: https://github.com/cardano-foundation/CIPs/pull/947

---

*Report generated: 2025-10-24*
*Aiken implementation path: `/Users/giovanni/Development/workspace/wsc-poc/src/programmable-tokens-onchain-aiken`*
