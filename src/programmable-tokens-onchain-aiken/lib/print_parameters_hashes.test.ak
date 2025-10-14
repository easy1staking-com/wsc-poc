use aiken/cbor
use aiken/primitive/bytearray
use cardano/transaction.{OutputReference}

test serialise_bootstrap_utxo() {
  trace bytearray.to_hex(
    cbor.serialise(
      OutputReference(
        #"2ad9a8a937482bd7243aa5b806335add3fc4731ced9a6cb12d2509667ab1160e",
        0,
      ),
    ),
  )
  True
}
