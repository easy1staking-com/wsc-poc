package org.cardanofoundation.cip143.model.bootstrap;

public record ProtocolBootstrapParams(ProtocolParams protocolParams,
                                      ProgrammableLogicGlobalParams programmableLogicGlobalPrams,
                                      ProgrammableLogicBaseParams programmableLogicBaseParams,
                                      IssuanceParams issuanceParams,
                                      DirectoryMintParams directoryMintParams,
                                      DirectorySpendParams directorySpendParams,
                                      TxInput programmableBaseRefInput,
                                      TxInput programmableGlobalRefInput,
                                      String txHash) {

}
