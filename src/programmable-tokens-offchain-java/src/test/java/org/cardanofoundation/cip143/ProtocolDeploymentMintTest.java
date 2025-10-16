package org.cardanofoundation.cip143;

import com.bloxbean.cardano.aiken.AikenScriptUtil;
import com.bloxbean.cardano.aiken.AikenTransactionEvaluator;
import com.bloxbean.cardano.client.address.AddressProvider;
import com.bloxbean.cardano.client.address.Credential;
import com.bloxbean.cardano.client.api.model.Amount;
import com.bloxbean.cardano.client.api.util.ValueUtil;
import com.bloxbean.cardano.client.function.helper.SignerProviders;
import com.bloxbean.cardano.client.plutus.blueprint.PlutusBlueprintUtil;
import com.bloxbean.cardano.client.plutus.blueprint.model.PlutusVersion;
import com.bloxbean.cardano.client.plutus.spec.BigIntPlutusData;
import com.bloxbean.cardano.client.plutus.spec.BytesPlutusData;
import com.bloxbean.cardano.client.plutus.spec.ConstrPlutusData;
import com.bloxbean.cardano.client.plutus.spec.ListPlutusData;
import com.bloxbean.cardano.client.quicktx.ScriptTx;
import com.bloxbean.cardano.client.transaction.spec.Asset;
import com.bloxbean.cardano.client.transaction.spec.MultiAsset;
import com.bloxbean.cardano.client.transaction.spec.Value;
import com.bloxbean.cardano.client.util.HexUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.cardanofoundation.cip143.model.blueprint.Plutus;
import org.cardanofoundation.cip143.model.blueprint.Validator;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigInteger;
import java.util.List;

@Slf4j
public class ProtocolDeploymentMintTest extends AbstractPreviewTest {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private String PROGRAMMABLE_LOGIC_GLOBAL_CONTRACT;

    private String PROGRAMMABLE_LOGIC_BASE_CONTRACT;

    private String PROTOCOL_PARAMS_CONTRACT;

    private String DIRECTORY_CONTRACT;

    private String ISSUANCE_CONTRACT;

    private String getCompiledCodeFor(String contractTitle, List<Validator> validators) {
        return validators.stream().filter(validator -> validator.title().equals(contractTitle)).findAny().get().compiledCode();
    }

    @BeforeEach
    public void loadContracts() throws Exception {
        var plutus = OBJECT_MAPPER.readValue(this.getClass().getClassLoader().getResourceAsStream("plutus.json"), Plutus.class);
        var validators = plutus.validators();
        PROGRAMMABLE_LOGIC_GLOBAL_CONTRACT = getCompiledCodeFor("programmable_logic_global.programmable_logic_global.withdraw", validators);
        PROGRAMMABLE_LOGIC_BASE_CONTRACT = getCompiledCodeFor("programmable_logic_base.programmable_logic_base.spend", validators);
        PROTOCOL_PARAMS_CONTRACT = getCompiledCodeFor("protocol_params_mint.protocol_params_mint.mint", validators);
        DIRECTORY_CONTRACT = getCompiledCodeFor("directory_mint.directory_mint.mint", validators);
        ISSUANCE_CONTRACT = getCompiledCodeFor("issuance_cbor_hex_mint.issuance_cbor_hex_mint.mint", validators);
    }

    @Test
    public void test() throws Exception {

        var utxosOpt = bfBackendService.getUtxoService().getUtxos(adminAccount.baseAddress(), 100, 1);
        if (!utxosOpt.isSuccessful()) {
            Assertions.fail("no utxos available");
        }
        var walletUtxos = utxosOpt.getValue();
        walletUtxos.forEach(utxo -> log.info("wallet utxo: {}", utxo));

        var utxo1 = walletUtxos.getFirst();
        var utxo2 = walletUtxos.getLast();

        Assertions.assertNotEquals(utxo1, utxo2);

        // Output Reference - utxo1
        var utxo1OutputReference = ConstrPlutusData.of(0,
                BytesPlutusData.of(HexUtil.decodeHexString(utxo1.getTxHash())),
                BigIntPlutusData.of(utxo1.getOutputIndex()));

        // Output Reference - utxo2
        var utxo2OutputReference = ConstrPlutusData.of(0,
                BytesPlutusData.of(HexUtil.decodeHexString(utxo2.getTxHash())),
                BigIntPlutusData.of(utxo2.getOutputIndex()));

        // Protocol Params contract parameterization
        var protocolParamsParameters = ListPlutusData.of(utxo1OutputReference);
        var protocolParamsContract = PlutusBlueprintUtil.getPlutusScriptFromCompiledCode(AikenScriptUtil.applyParamToScript(protocolParamsParameters, PROTOCOL_PARAMS_CONTRACT), PlutusVersion.v3);

        // Programmable Logic Global parameterization
        var programmableLogicGlobalParameters = ListPlutusData.of(ConstrPlutusData.of(0, BytesPlutusData.of(protocolParamsContract.getScriptHash())));
        var programmableLogicGlobalContract = PlutusBlueprintUtil.getPlutusScriptFromCompiledCode(AikenScriptUtil.applyParamToScript(programmableLogicGlobalParameters, PROGRAMMABLE_LOGIC_GLOBAL_CONTRACT), PlutusVersion.v3);

        // Programmable Logic Base parameterization
        var programmableLogicBaseParameters = ListPlutusData.of(ConstrPlutusData.of(0,
                        ConstrPlutusData.of(1,
                                BytesPlutusData.of(programmableLogicGlobalContract.getScriptHash()))
                )
        );
        var programmableLogicBaseContract = PlutusBlueprintUtil.getPlutusScriptFromCompiledCode(AikenScriptUtil.applyParamToScript(programmableLogicBaseParameters, PROGRAMMABLE_LOGIC_BASE_CONTRACT), PlutusVersion.v3);


        // The payment credentials where all prog tokens live
        var baseProgrammableLogicPaymentCredential = ConstrPlutusData.of(0,
                BytesPlutusData.of(programmableLogicBaseContract.getScriptHash())
        );

        // Issuance Mint parameterization
        // Protocol Params contract parameterization
        var issuanceParameters = ListPlutusData.of(utxo2OutputReference);
        var issuanceContract = PlutusBlueprintUtil.getPlutusScriptFromCompiledCode(AikenScriptUtil.applyParamToScript(issuanceParameters, ISSUANCE_CONTRACT), PlutusVersion.v3);

        // Directory parameterization
        var directoryParameters = ListPlutusData.of(
                ConstrPlutusData.of(0,
                        BytesPlutusData.of(HexUtil.decodeHexString(utxo1.getTxHash())),
                        BigIntPlutusData.of(utxo1.getOutputIndex())),
                BytesPlutusData.of(issuanceContract.getScriptHash())
        );
        var directoryContract = PlutusBlueprintUtil.getPlutusScriptFromCompiledCode(AikenScriptUtil.applyParamToScript(directoryParameters, DIRECTORY_CONTRACT), PlutusVersion.v3);


        // Protocol Params MINT - NFT, address, datum and value
        var protocolParamNft = Asset.builder()
                .name(HexUtil.encodeHexString("ProtocolParams".getBytes(), true))
                .value(BigInteger.ONE)
                .build();

        var protocolParamsContractAddress = AddressProvider.getEntAddress(Credential.fromScript(protocolParamsContract.getScriptHash()), network);
        log.info("protocolParamsContractAddress: {}", protocolParamsContractAddress.getAddress());

        var protocolParamsDatum = ConstrPlutusData.of(0,
                // FIXME: these are NOT the correct one, just testing if it passes validation
                BytesPlutusData.of(directoryContract.getScriptHash()),
                // This is the payment credential for ALL permissioned tokens
                baseProgrammableLogicPaymentCredential
        );

        Value protocolParamsValue = Value.builder()
                .coin(Amount.ada(1).getQuantity())
                .multiAssets(List.of(
                        MultiAsset.builder()
                                .policyId(protocolParamsContract.getPolicyId())
                                .assets(List.of(protocolParamNft))
                                .build()
                ))
                .build();

        // Directory MINT - NFT, address, datum and value
        var directoryNft = Asset.builder()
                .name("0x")
                .value(BigInteger.ONE)
                .build();

        var directoryAddress = AddressProvider.getEntAddress(Credential.fromScript(directoryContract.getScriptHash()), network);
        log.info("directoryAddress: {}", directoryAddress.getAddress());

        var directoryDatum = ConstrPlutusData.of(0,
                BytesPlutusData.of(""),
                BytesPlutusData.of(HexUtil.decodeHexString("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")),
                ConstrPlutusData.of(0, BytesPlutusData.of("")),
                ConstrPlutusData.of(0, BytesPlutusData.of("")),
                BytesPlutusData.of(""));

        Value directoryValue = Value.builder()
                .coin(Amount.ada(1).getQuantity())
                .multiAssets(List.of(
                        MultiAsset.builder()
                                .policyId(directoryContract.getPolicyId())
                                .assets(List.of(directoryNft))
                                .build()
                ))
                .build();

        // Directory MINT - NFT, address, datum and value
        var issuanceNft = Asset.builder()
                .name(HexUtil.encodeHexString("IssuanceCborHex".getBytes(), true))
                .value(BigInteger.ONE)
                .build();

        var issuanceAddress = AddressProvider.getEntAddress(Credential.fromScript(issuanceContract.getScriptHash()), network);
        log.info("issuanceAddress: {}", issuanceAddress.getAddress());

        Value issuanceValue = Value.builder()
                .coin(Amount.ada(1).getQuantity())
                .multiAssets(List.of(
                        MultiAsset.builder()
                                .policyId(issuanceContract.getPolicyId())
                                .assets(List.of(issuanceNft))
                                .build()
                ))
                .build();

        var tx = new ScriptTx()
                //spend all wallets (coz we need to burn the bootstrap utxo)
                .collectFrom(walletUtxos)
                // Redeemer is DirectoryInit (constr(0))
                .mintAsset(directoryContract, directoryNft, ConstrPlutusData.of(0))
                // Redeemer unused
                .mintAsset(protocolParamsContract, protocolParamNft, ConstrPlutusData.of(1))
                // Redeemer unused
                .mintAsset(issuanceContract, issuanceNft, ConstrPlutusData.of(2))
                // Protocol Params
                .payToContract(protocolParamsContractAddress.getAddress(), ValueUtil.toAmountList(protocolParamsValue), protocolParamsDatum)
                // Directory Params
                .payToContract(directoryAddress.getAddress(), ValueUtil.toAmountList(directoryValue), directoryDatum)
                // Protocol Params
                .payToContract(issuanceAddress.getAddress(), ValueUtil.toAmountList(issuanceValue), ConstrPlutusData.of(0))
                .withChangeAddress(adminAccount.baseAddress());

        var transaction = quickTxBuilder.compose(tx)
                .withSigner(SignerProviders.signerFrom(adminAccount))
                .withTxEvaluator(new AikenTransactionEvaluator(bfBackendService))
                .feePayer(adminAccount.baseAddress())
                .build();

        log.info("tx: {}", transaction.serializeToHex());
        log.info("tx: {}", OBJECT_MAPPER.writeValueAsString(transaction));


    }


}
