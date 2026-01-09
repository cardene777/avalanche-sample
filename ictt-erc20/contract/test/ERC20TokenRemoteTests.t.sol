// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

import {ERC20TokenTransferrerTest} from "./base/ERC20TokenTransferrerTests.t.sol";
import {TokenRemoteTest} from "./base/TokenRemoteTests.t.sol";
import {IERC20SendAndCallReceiver} from "../src/ictt/interfaces/IERC20SendAndCallReceiver.sol";
import {TokenRemote} from "../src/ictt/TokenRemote/TokenRemote.sol";
import {TokenRemoteSettings} from "../src/ictt/TokenRemote/interfaces/ITokenRemote.sol";
import {ERC20TokenRemoteUpgradeable} from "../src/ictt/TokenRemote/ERC20TokenRemoteUpgradeable.sol";
import {ERC20TokenRemote} from "../src/ictt/TokenRemote/ERC20TokenRemote.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ExampleERC20} from "@mocks/ExampleERC20.sol";
import {SendTokensInput} from "../src/ictt/interfaces/ITokenTransferrer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICMInitializable} from "@utilities/ICMInitializable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * ERC20TokenRemoteコントラクトの統合テスト
 * @dev ERC20トークンのRemote側（受信先チェーン）の機能をテストする
 */
contract ERC20TokenRemoteTest is ERC20TokenTransferrerTest, TokenRemoteTest {
    using SafeERC20 for IERC20;

    string public constant MOCK_TOKEN_NAME = "Test Token";
    string public constant MOCK_TOKEN_SYMBOL = "TST";

    ERC20TokenRemoteUpgradeable public app;

    /**
     * @notice テスト環境のセットアップ
     * @dev ERC20TokenRemoteコントラクトを初期化し、初期トークンを発行する
     */
    function setUp() public virtual override {
        TokenRemoteTest.setUp();

        tokenDecimals = 14;
        tokenHomeDecimals = 18;
        app = ERC20TokenRemoteUpgradeable(address(_createNewRemoteInstance()));

        erc20TokenTransferrer = app;
        tokenRemote = app;
        tokenTransferrer = app;

        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(0), address(this), 10e18);

        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        app.receiveTeleporterMessage(
            DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
            DEFAULT_TOKEN_HOME_ADDRESS,
            _encodeSingleHopSendMessage(10e18, address(this))
        );
    }

    /**
     * @notice 非アップグレード可能なコントラクトの初期化が正しく動作することを確認するテスト
     * @dev ERC20TokenRemoteコントラクトをデプロイして、blockchainIDが正しく設定されることを検証
     */
    function testNonUpgradeableInitialization() public {
        app = new ERC20TokenRemote(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals
        );
        assertEq(app.getBlockchainID(), DEFAULT_TOKEN_REMOTE_BLOCKCHAIN_ID);
    }

    /**
     * @notice 初期化が無効化されている場合に初期化が失敗することを確認するテスト
     * @dev ICMInitializable.Disallowedで初期化を無効にし、InvalidInitializationエラーが発生することを検証
     */
    function testDisableInitialization() public {
        app = new ERC20TokenRemoteUpgradeable(ICMInitializable.Disallowed);
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        app.initialize(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals
        );
    }

    /**
     * @notice TeleporterRegistryアドレスがゼロアドレスの場合に初期化が失敗することを確認するテスト
     * @dev ゼロアドレスでの初期化時に適切なエラーメッセージが返されることを検証
     */
    function testZeroTeleporterRegistryAddress() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: address(0),
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals,
            "TeleporterRegistryApp: zero Teleporter registry address"
        );
    }

    /**
     * @notice TeleporterManagerアドレスがゼロアドレスの場合に初期化が失敗することを確認するテスト
     * @dev ゼロアドレスでの初期化時にOwnableInvalidOwnerエラーが発生することを検証
     */
    function testZeroTeleporterManagerAddress() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(0),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals,
            abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0))
        );
    }

    /**
     * @notice TokenHomeBlockchainIDがゼロの場合に初期化が失敗することを確認するテスト
     * @dev ゼロ値での初期化時に"zero token home blockchain ID"エラーが発生することを検証
     */
    function testZeroTokenHomeBlockchainID() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: bytes32(0),
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals,
            _formatErrorMessage("zero token home blockchain ID")
        );
    }

    /**
     * @notice TokenHomeと同じブロックチェーンにデプロイしようとした場合に初期化が失敗することを確認するテスト
     * @dev 同じblockchainIDでの初期化時に適切なエラーメッセージが返されることを検証
     */
    function testDeployToSameBlockchain() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_REMOTE_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals,
            _formatErrorMessage("cannot deploy to same blockchain as token home")
        );
    }

    /**
     * @notice TokenHomeアドレスがゼロアドレスの場合に初期化が失敗することを確認するテスト
     * @dev ゼロアドレスでの初期化時に"zero token home address"エラーが発生することを検証
     */
    function testZeroTokenHomeAddress() public {
        _invalidInitialization(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: address(0),
                tokenHomeDecimals: 18
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            18,
            _formatErrorMessage("zero token home address")
        );
    }

    /**
     * @notice 別の手数料アセットを使用してトークンを送信できることを確認するテスト
     * @dev メインのトークンとは異なる手数料トークンを使用して送信が正常に行われることを検証
     */
    function testSendWithSeparateFeeAsset() public {
        uint256 amount = 200_000;
        uint256 feeAmount = 100;
        ExampleERC20 separateFeeAsset = new ExampleERC20();
        SendTokensInput memory input = _createDefaultSendTokensInput();
        input.primaryFeeTokenAddress = address(separateFeeAsset);
        input.primaryFee = feeAmount;

        IERC20(separateFeeAsset).safeIncreaseAllowance(address(tokenTransferrer), feeAmount);
        vm.expectCall(
            address(separateFeeAsset),
            abi.encodeCall(
                IERC20.transferFrom, (address(this), address(tokenTransferrer), feeAmount)
            )
        );
        // ユーザーから資金を転送するため、トークントランスファラーのallowanceを増やす
        IERC20(app).safeIncreaseAllowance(address(tokenTransferrer), amount);

        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(this), address(0), amount);
        _checkExpectedTeleporterCallsForSend(_createSingleHopTeleporterMessageInput(input, amount));
        vm.expectEmit(true, true, true, true, address(tokenTransferrer));
        emit TokensSent(_MOCK_MESSAGE_ID, address(this), input, amount);
        _send(input, amount);
    }

    /**
     * @notice decimals関数が正しい値を返すことを確認するテスト
     * @dev 初期化時に設定したdecimals値が正しく返されることを検証
     */
    function testDecimals() public view {
        uint8 res = app.decimals();
        assertEq(tokenDecimals, res);
    }

    function _createNewRemoteInstance() internal override returns (TokenRemote) {
        ERC20TokenRemoteUpgradeable instance =
            new ERC20TokenRemoteUpgradeable(ICMInitializable.Allowed);
        instance.initialize(
            TokenRemoteSettings({
                teleporterRegistryAddress: MOCK_TELEPORTER_REGISTRY_ADDRESS,
                teleporterManager: address(this),
                minTeleporterVersion: 1,
                tokenHomeBlockchainID: DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID,
                tokenHomeAddress: DEFAULT_TOKEN_HOME_ADDRESS,
                tokenHomeDecimals: tokenHomeDecimals
            }),
            MOCK_TOKEN_NAME,
            MOCK_TOKEN_SYMBOL,
            tokenDecimals
        );
        return instance;
    }

    function _checkExpectedWithdrawal(address recipient, uint256 amount) internal override {
        vm.expectEmit(true, true, true, true, address(tokenRemote));
        emit TokensWithdrawn(recipient, amount);
        vm.expectEmit(true, true, true, true, address(tokenRemote));
        emit Transfer(address(0), recipient, amount);
    }

    function _setUpExpectedSendAndCall(
        bytes32 sourceBlockchainID,
        OriginSenderInfo memory originInfo,
        address recipient,
        uint256 amount,
        bytes memory payload,
        uint256 gasLimit,
        bool targetHasCode,
        bool expectSuccess
    ) internal override {
        // 転送されたトークンはコントラクト自体にミントされる
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(0), address(tokenRemote), amount);

        // 受信者コントラクトはそれらを使用することが承認される
        vm.expectEmit(true, true, true, true, address(app));
        emit Approval(address(app), DEFAULT_RECIPIENT_CONTRACT_ADDRESS, amount);

        if (targetHasCode) {
            vm.etch(recipient, new bytes(1));

            bytes memory expectedCalldata = abi.encodeCall(
                IERC20SendAndCallReceiver.receiveTokens,
                (
                    sourceBlockchainID,
                    originInfo.tokenTransferrerAddress,
                    originInfo.senderAddress,
                    address(app),
                    amount,
                    payload
                )
            );
            if (expectSuccess) {
                vm.mockCall(recipient, expectedCalldata, new bytes(0));
            } else {
                vm.mockCallRevert(recipient, expectedCalldata, new bytes(0));
            }
            vm.expectCall(recipient, 0, uint64(gasLimit), expectedCalldata);
        } else {
            vm.etch(recipient, new bytes(0));
        }

        // 受信者コントラクトの承認をリセット
        vm.expectEmit(true, true, true, true, address(app));
        emit Approval(address(app), DEFAULT_RECIPIENT_CONTRACT_ADDRESS, 0);

        if (targetHasCode && expectSuccess) {
            // 呼び出しは成功するはず
            vm.expectEmit(true, true, true, true, address(app));
            emit CallSucceeded(DEFAULT_RECIPIENT_CONTRACT_ADDRESS, amount);
        } else {
            // 呼び出しは失敗するはず
            vm.expectEmit(true, true, true, true, address(app));
            emit CallFailed(DEFAULT_RECIPIENT_CONTRACT_ADDRESS, amount);

            // 金額はフォールバック受信者に送信されるはず
            vm.expectEmit(true, true, true, true, address(app));
            emit Transfer(address(app), address(DEFAULT_FALLBACK_RECIPIENT_ADDRESS), amount);
        }
    }

    function _setUpExpectedZeroAmountRevert() internal override {
        vm.expectRevert(_formatErrorMessage("insufficient tokens to transfer"));
    }

    function _setUpExpectedDeposit(uint256 amount, uint256 feeAmount) internal virtual override {
        // feeAmountが0より大きい場合、手数料をトークントランスファラーに転送
        if (feeAmount > 0) {
            IERC20(app).safeIncreaseAllowance(address(tokenTransferrer), feeAmount);
        }

        // ユーザーから資金を転送するため、トークントランスファラーのallowanceを増やす
        IERC20(app).safeIncreaseAllowance(address(tokenTransferrer), amount);

        // 送信前のバーンを考慮
        vm.expectEmit(true, true, true, true, address(app));
        emit Transfer(address(this), address(0), amount);

        if (feeAmount > 0) {
            vm.expectEmit(true, true, true, true, address(app));
            emit Transfer(address(this), address(tokenTransferrer), feeAmount);
        }
    }

    function _getTotalSupply() internal view override returns (uint256) {
        return app.totalSupply();
    }

    function _setUpMockMint(address, uint256) internal pure override {
        // ERC20TokenRemoteUpgradeableのミント処理はリモートコントラクト上の内部呼び出しであるため、
        // モック化する必要はない
        return;
    }

    function _invalidInitialization(
        TokenRemoteSettings memory settings,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals_,
        bytes memory expectedErrorMessage
    ) private {
        app = new ERC20TokenRemoteUpgradeable(ICMInitializable.Allowed);
        vm.expectRevert(expectedErrorMessage);
        app.initialize(settings, tokenName, tokenSymbol, tokenDecimals_);
    }
}
