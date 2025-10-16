// Unit tests for core types
use aiken/builtin
use types.{node_key_tn, node_key_tn_prefix, origin_node_tn}

// Test that origin node token name is correct
test origin_node_tn_is_correct() {
  origin_node_tn == #""
}

// Test that node key token name prefix is correct
test node_key_tn_prefix_is_correct() {
  node_key_tn_prefix == #"01"
}

// Test node_key_tn function creates correct token name
test node_key_tn_creates_correct_name() {
  let key = #"aabbccdd"
  let expected = builtin.append_bytearray(#"01", #"aabbccdd")
  node_key_tn(key) == expected
}

// Test node_key_tn with empty key
test node_key_tn_with_empty_key() {
  let key = #""
  let expected = #"01"
  node_key_tn(key) == expected
}

// Test node_key_tn with 28-byte currency symbol
test node_key_tn_with_currency_symbol() {
  let cs = #"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c"
  let result = node_key_tn(cs)
  let expected_prefix = builtin.slice_bytearray(0, 1, result)

  // Should start with prefix
  expected_prefix == #"01" && // Should be 29 bytes (1 prefix + 28 CS)
  builtin.length_of_bytearray(result) == 29
}
