package org.cardanofoundation.cip143.model.bootstrap;

public record ProtocolBootstrapParams(ProtocolParams protocolParams,
                                      ProgrammableLogicGlobalParams programmableLogicGlobalPrams,
                                      ProgrammableLogicBaseParams programmableLogicBaseParams,
                                      IssuanceParams issuanceParams,
                                      DirectoryParams directoryParams,
                                      String txHash) {

}
