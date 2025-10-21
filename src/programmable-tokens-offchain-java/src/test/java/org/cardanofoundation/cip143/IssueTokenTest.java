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
import org.apache.catalina.startup.AddPortOffsetRule;
import org.cardanofoundation.cip143.model.blueprint.Plutus;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigInteger;
import java.util.List;

@Slf4j
public class IssueTokenTest extends AbstractPreviewTest {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private static final String SUBSTANDARD_ISSUE_CONTRACT = "585701010029800aba2aba1aab9eaab9dab9a4888896600264646644b30013370e900218031baa00289919b87375a6012008906400980418039baa0028a504014600c600e002600c004600c00260066ea801a29344d9590011";

    private static final String SUBSTANDARD_TRANSFER_CONTRACT = "585701010029800aba2aba1aab9eaab9dab9a4888896600264646644b30013370e900218031baa00289919b87375a6012008904801980418039baa0028a504014600c600e002600c004600c00260066ea801a29344d9590011";

    private String ISSUANCE_MINT;

    private String PROGRAMMABLE_LOGIC_BASE_CONTRACT;


    @BeforeEach
    public void loadContracts() throws Exception {
        var plutus = OBJECT_MAPPER.readValue(this.getClass().getClassLoader().getResourceAsStream("plutus.json"), Plutus.class);
        var validators = plutus.validators();
        ISSUANCE_MINT = getCompiledCodeFor("issuance_mint.issuance_mint.mint", validators);

        PROGRAMMABLE_LOGIC_BASE_CONTRACT = getCompiledCodeFor("programmable_logic_base.programmable_logic_base.spend", validators);
    }

    @Test
    public void test() throws Exception {

        var bootstrapTxHash = "2592ff5b2810679c30996c309080a3635071f923b43edb494a87597c1e6a5be5";

        // Protocol Params 2592ff5b2810679c30996c309080a3635071f923b43edb494a87597c1e6a5be5:0
        // Directory 2592ff5b2810679c30996c309080a3635071f923b43edb494a87597c1e6a5be5:1
        // Issuance 2592ff5b2810679c30996c309080a3635071f923b43edb494a87597c1e6a5be5:2

        var programmableLogicBaseScriptHash = "7e9ddd4a91775e1e76867f164ebaf2113301f4dc769f24efedbdca24";

        var utxosOpt = bfBackendService.getUtxoService().getUtxos(adminAccount.baseAddress(), 100, 1);
        if (!utxosOpt.isSuccessful()) {
            Assertions.fail("no utxos available");
        }
        var walletUtxos = utxosOpt.getValue();
        walletUtxos.forEach(utxo -> log.info("wallet utxo: {}", utxo));

        var directoryOpt = bfBackendService.getUtxoService().getTxOutput(bootstrapTxHash, 1);
        if (!directoryOpt.isSuccessful()) {
            Assertions.fail("no directory found");
        }
        var directory = directoryOpt.getValue();

        var substandardIssueContract = PlutusBlueprintUtil.getPlutusScriptFromCompiledCode(SUBSTANDARD_ISSUE_CONTRACT, PlutusVersion.v3);
        var issueAddress = AddressProvider.getRewardAddress(Credential.fromKey(substandardIssueContract.getScriptHash()), network);
        log.info("issueAddress: {}", issueAddress.getAddress());

        var substandardTransferContract = PlutusBlueprintUtil.getPlutusScriptFromCompiledCode(SUBSTANDARD_TRANSFER_CONTRACT, PlutusVersion.v3);

        // Issuance Parameterization
        var issuanceParameters = ListPlutusData.of(
                ConstrPlutusData.of(0,
                        BytesPlutusData.of(HexUtil.decodeHexString(programmableLogicBaseScriptHash))
                ),
                BytesPlutusData.of(substandardIssueContract.getScriptHash())
        );
        var issuanceContract = PlutusBlueprintUtil.getPlutusScriptFromCompiledCode(AikenScriptUtil.applyParamToScript(issuanceParameters, ISSUANCE_MINT), PlutusVersion.v3);

        var issuanceRedeemer = ConstrPlutusData.of(0, ConstrPlutusData.of(0, BytesPlutusData.of(substandardTransferContract.getScriptHash())));

        // Programmable Token Mint
        var pintToken = Asset.builder()
                .name(HexUtil.encodeHexString("PINT".getBytes(), true))
                .value(BigInteger.valueOf(1_000_000_000L))
                .build();

        Value pintTokenValue = Value.builder()
                .coin(Amount.ada(1).getQuantity())
                .multiAssets(List.of(
                        MultiAsset.builder()
                                .policyId(issuanceContract.getPolicyId())
                                .assets(List.of(pintToken))
                                .build()
                ))
                .build();

        var targetAddress = AddressProvider.getEntAddress(Credential.fromScript("97f1c6fa3daa5216fd703eb2c25144cede4145200c396fbab0db1223"), network);

        var tx = new ScriptTx()
                .collectFrom(walletUtxos)
                .withdraw(issueAddress.getAddress(), BigInteger.ZERO, BigIntPlutusData.of(100))
                // Redeemer is DirectoryInit (constr(0))
                .mintAsset(issuanceContract, pintToken, issuanceRedeemer)
                .payToContract(targetAddress.getAddress(), ValueUtil.toAmountList(pintTokenValue), ConstrPlutusData.of(0))
                .withChangeAddress(adminAccount.baseAddress());

        var transaction = quickTxBuilder.compose(tx)
                .withSigner(SignerProviders.signerFrom(adminAccount))
                .withTxEvaluator(new AikenTransactionEvaluator(bfBackendService))
                .feePayer(adminAccount.baseAddress())
                .buildAndSign();

        log.info("tx: {}", transaction.serializeToHex());
        log.info("tx: {}", OBJECT_MAPPER.writeValueAsString(transaction));

        var result = bfBackendService.getTransactionService().submitTransaction(transaction.serialize());
        if (result.isSuccessful()) {
            log.info("submitted: {}", result.getValue());
        } else {
            log.warn("error: {}", result.getResponse());
        }


    }


}
