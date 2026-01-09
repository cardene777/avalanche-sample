// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

import {ERC20TokenTransferrerTest} from "./base/ERC20TokenTransferrerTests.t.sol";
import {TokenHomeTest} from "./base/TokenHomeTests.t.sol";
import {IERC20SendAndCallReceiver} from "../src/ictt/interfaces/IERC20SendAndCallReceiver.sol";
import {SendTokensInput} from "../src/ictt/interfaces/ITokenTransferrer.sol";
import {ERC20TokenHomeUpgradeable} from "../src/ictt/TokenHome/ERC20TokenHomeUpgradeable.sol";
import {ERC20TokenHome} from "../src/ictt/TokenHome/ERC20TokenHome.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ExampleERC20} from "@mocks/ExampleERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TeleporterMessageInput, TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";
import {TokenScalingUtils} from "@utilities/TokenScalingUtils.sol";
import {RemoteTokenTransferrerSettings} from "../src/ictt/TokenHome/interfaces/ITokenHome.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICMInitializable} from "@utilities/ICMInitializable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * ERC20TokenHomeコントラクトの統合テスト
 * @dev ERC20トークンのHome側（送信元チェーン）の機能をテストする
 */
contract ERC20TokenHomeTest is ERC20TokenTransferrerTest, TokenHomeTest {
    using SafeERC20 for IERC20;

    ERC20TokenHomeUpgradeable public app;
    IERC20 public mockERC20;

    /**
     * @notice テスト環境のセットアップ
     * @dev モックERC20トークンとERC20TokenHomeコントラクトを初期化する
     */
    function setUp() public override {
        TokenHomeTest.setUp();

        mockERC20 = new ExampleERC20();
        tokenHomeDecimals = 6;
        app = new ERC20TokenHomeUpgradeable(ICMInitializable.Allowed);
        app.initialize(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            MOCK_TELEPORTER_MESSENGER_ADDRESS,
            1,
            address(mockERC20),
            tokenHomeDecimals
        );
        erc20TokenTransferrer = app;
        tokenHome = app;
        tokenTransferrer = app;

        transferredToken = mockERC20;
    }

    /**
     * @notice 非アップグレード可能なコントラクトの初期化が正しく動作することを確認するテスト
     * @dev ERC20TokenHomeコントラクトをデプロイして、blockchainIDが正しく設定されることを検証
     */
    function testNonUpgradeableInitialization() public {
        app = new ERC20TokenHome(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            address(this),
            1,
            address(mockERC20),
            tokenHomeDecimals
        );
        assertEq(app.getBlockchainID(), DEFAULT_TOKEN_HOME_BLOCKCHAIN_ID);
    }

    /**
     * @notice 初期化が無効化されている場合に初期化が失敗することを確認するテスト
     * @dev ICMInitializable.Disallowedで初期化を無効にし、InvalidInitializationエラーが発生することを検証
     */
    function testDisableInitialization() public {
        app = new ERC20TokenHomeUpgradeable(ICMInitializable.Disallowed);
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        app.initialize(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            address(this),
            1,
            address(mockERC20),
            tokenHomeDecimals
        );
    }

    /**
     * @notice TeleporterRegistryアドレスがゼロアドレスの場合に初期化が失敗することを確認するテスト
     * @dev ゼロアドレスでの初期化時に適切なエラーメッセージが返されることを検証
     */
    function testZeroTeleporterRegistryAddress() public {
        _invalidInitialization(
            address(0),
            address(this),
            address(mockERC20),
            tokenHomeDecimals,
            "TeleporterRegistryApp: zero Teleporter registry address"
        );
    }

    /**
     * @notice TeleporterManagerアドレスがゼロアドレスの場合に初期化が失敗することを確認するテスト
     * @dev ゼロアドレスでの初期化時にOwnableInvalidOwnerエラーが発生することを検証
     */
    function testZeroTeleporterManagerAddress() public {
        _invalidInitialization(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            address(0),
            address(mockERC20),
            tokenHomeDecimals,
            abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0))
        );
    }

    /**
     * @notice 手数料トークンアドレスがゼロアドレスの場合に初期化が失敗することを確認するテスト
     * @dev ゼロアドレスでの初期化時に"zero token address"エラーが発生することを検証
     */
    function testZeroFeeTokenAddress() public {
        _invalidInitialization(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            address(this),
            address(0),
            tokenHomeDecimals,
            _formatErrorMessage("zero token address")
        );
    }

    /**
     * @notice トークンのdecimals値が上限を超える場合に初期化が失敗することを確認するテスト
     * @dev MAX_TOKEN_DECIMALS + 1の値で初期化時に"token decimals too high"エラーが発生することを検証
     */
    function testTokenDecimalsTooHigh() public {
        _invalidInitialization(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            address(this),
            address(mockERC20),
            uint8(TokenScalingUtils.MAX_TOKEN_DECIMALS) + 1,
            _formatErrorMessage("token decimals too high")
        );
    }

    /**
     * @notice スケーリングダウンによりゼロHomeトークン額を受信する場合にエラーが発生することを確認するテスト
     * @dev リモートから受信したトークン額がスケールダウンされてゼロになる場合に"zero token amount"エラーが発生することを検証
     */
    function testReceiveZeroHomeTokenAmount() public {
        // 受信額をゼロHomeトークンにスケールダウンする登録済みリモートをセットアップ
        uint256 tokenMultiplier = 100_000;
        _setUpRegisteredRemote(
            DEFAULT_TOKEN_REMOTE_BLOCKCHAIN_ID,
            DEFAULT_TOKEN_REMOTE_ADDRESS,
            0,
            tokenMultiplier,
            true
        );

        // Homeトークンをリモートに送信し、スケール後のトークン量での期待される呼び出しを確認
        SendTokensInput memory input = _createDefaultSendTokensInput();
        uint256 amount = 1;
        _setUpExpectedDeposit(amount, input.primaryFee);

        uint256 scaledAmount = tokenMultiplier * amount;
        _checkExpectedTeleporterCallsForSend(
            _createSingleHopTeleporterMessageInput(input, scaledAmount)
        );
        vm.expectEmit(true, true, true, true, address(tokenTransferrer));
        emit TokensSent(_MOCK_MESSAGE_ID, address(this), input, scaledAmount);
        _send(input, amount);

        // `scaledAmount`未満のトークンをリモートから受信し、ゼロHomeトークンにスケールダウンされることを確認
        vm.expectRevert(_formatErrorMessage("zero token amount"));
        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        tokenHome.receiveTeleporterMessage(
            DEFAULT_TOKEN_REMOTE_BLOCKCHAIN_ID,
            DEFAULT_TOKEN_REMOTE_ADDRESS,
            _encodeSingleHopSendMessage(scaledAmount - 1, DEFAULT_RECIPIENT_ADDRESS)
        );
    }

    /**
     * @notice 宛先登録時に必要な担保額が正しく切り上げられることを確認するテスト
     * @dev トークンマルチプライヤーに基づいて担保額が適切に計算されることを検証
     */
    function testRegisterDestinationRoundUpCollateralNeeded() public {
        _setUpRegisteredRemote(
            DEFAULT_TOKEN_REMOTE_BLOCKCHAIN_ID, DEFAULT_TOKEN_REMOTE_ADDRESS, 11, 10, true
        );
        RemoteTokenTransferrerSettings memory settings = tokenHome.getRemoteTokenTransferrerSettings(
            DEFAULT_TOKEN_REMOTE_BLOCKCHAIN_ID, DEFAULT_TOKEN_REMOTE_ADDRESS
        );
        assertEq(settings.collateralNeeded, 2);
    }

    /**
     * @notice スケールアップされたトークン額が正しく送信されることを確認するテスト
     * @dev トークンマルチプライヤーを使用して送信額が適切にスケールアップされることを検証
     */
    function testSendScaledUpAmount() public {
        uint256 amount = 100;
        uint256 feeAmount = 1;

        SendTokensInput memory input = _createDefaultSendTokensInput();
        input.primaryFee = feeAmount;

        // 送信される実際の金額は1e2倍される必要がある
        uint256 tokenMultiplier = 1e2;
        _setUpRegisteredRemote(
            input.destinationBlockchainID,
            input.destinationTokenTransferrerAddress,
            0,
            tokenMultiplier,
            true
        );
        _setUpExpectedDeposit(amount, input.primaryFee);
        TeleporterMessageInput memory expectedMessage = TeleporterMessageInput({
            destinationBlockchainID: input.destinationBlockchainID,
            destinationAddress: input.destinationTokenTransferrerAddress,
            feeInfo: TeleporterFeeInfo({
                feeTokenAddress: address(transferredToken),
                amount: input.primaryFee
            }),
            requiredGasLimit: input.requiredGasLimit,
            allowedRelayerAddresses: new address[](0),
            message: _encodeSingleHopSendMessage(amount * tokenMultiplier, DEFAULT_RECIPIENT_ADDRESS)
        });
        _checkExpectedTeleporterCallsForSend(expectedMessage);
        vm.expectEmit(true, true, true, true, address(tokenTransferrer));
        emit TokensSent(_MOCK_MESSAGE_ID, address(this), input, amount * tokenMultiplier);
        _send(input, amount);
    }

    function _checkExpectedWithdrawal(address recipient, uint256 amount) internal override {
        vm.expectEmit(true, true, true, true, address(tokenHome));
        emit TokensWithdrawn(recipient, amount);
        vm.expectCall(
            address(mockERC20), abi.encodeCall(IERC20.transfer, (address(recipient), amount))
        );
        vm.expectEmit(true, true, true, true, address(mockERC20));
        emit Transfer(address(app), recipient, amount);
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
        // 受信者コントラクトはトークンホームコントラクトからトークンを使用することが承認される
        vm.expectEmit(true, true, true, true, address(mockERC20));
        emit Approval(address(app), DEFAULT_RECIPIENT_CONTRACT_ADDRESS, amount);

        if (targetHasCode) {
            vm.etch(recipient, new bytes(1));

            bytes memory expectedCalldata = abi.encodeCall(
                IERC20SendAndCallReceiver.receiveTokens,
                (
                    sourceBlockchainID,
                    originInfo.tokenTransferrerAddress,
                    originInfo.senderAddress,
                    address(mockERC20),
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
        vm.expectEmit(true, true, true, true, address(mockERC20));
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
            vm.expectEmit(true, true, true, true, address(mockERC20));
            emit Transfer(address(app), address(DEFAULT_FALLBACK_RECIPIENT_ADDRESS), amount);
        }
    }

    function _addCollateral(
        bytes32 remoteBlockchainID,
        address remoteTokenTransferrerAddress,
        uint256 amount
    ) internal override {
        app.addCollateral(remoteBlockchainID, remoteTokenTransferrerAddress, amount);
    }

    function _setUpDeposit(
        uint256 amount
    ) internal virtual override {
        // ユーザーから資金を転送するため、トークントランスファラーのallowanceを増やす
        transferredToken.safeIncreaseAllowance(address(tokenTransferrer), amount);
    }

    function _setUpExpectedZeroAmountRevert() internal override {
        vm.expectRevert("SafeERC20TransferFrom: balance not increased");
    }

    function _setUpExpectedDeposit(uint256 amount, uint256 feeAmount) internal virtual override {
        // feeAmountが0より大きい場合、手数料をトークントランスファラーに転送
        if (feeAmount > 0) {
            transferredToken.safeIncreaseAllowance(address(tokenTransferrer), feeAmount);
            vm.expectCall(
                address(transferredToken),
                abi.encodeCall(
                    IERC20.transferFrom, (address(this), address(tokenTransferrer), feeAmount)
                )
            );
        }
        // ユーザーから資金を転送するため、トークントランスファラーのallowanceを増やす
        transferredToken.safeIncreaseAllowance(address(tokenTransferrer), amount);

        // ユーザーからトークントランスファラーに資金を入金するためにtransferFromが呼ばれることを確認
        // これはERC20TokenHomeUpgradeableが手数料トークン自体ではないためである
        vm.expectCall(
            address(transferredToken),
            abi.encodeCall(IERC20.transferFrom, (address(this), address(tokenTransferrer), amount))
        );
        vm.expectEmit(true, true, true, true, address(transferredToken));
        emit Transfer(address(this), address(tokenTransferrer), amount);
    }

    function _invalidInitialization(
        address teleporterRegistryAddress,
        address teleporterManagerAddress,
        address feeTokenAddress,
        uint8 tokenDecimals,
        bytes memory expectedErrorMessage
    ) private {
        app = new ERC20TokenHomeUpgradeable(ICMInitializable.Allowed);
        vm.expectRevert(expectedErrorMessage);
        app.initialize(
            teleporterRegistryAddress, teleporterManagerAddress, 1, feeTokenAddress, tokenDecimals
        );
    }
}
