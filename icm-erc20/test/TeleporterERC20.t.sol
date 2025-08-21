// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/TeleporterERC20.sol";
import "@avalabs/teleporter/ITeleporterMessenger.sol";

/**
 * @title TeleporterERC20テストコントラクト
 */
contract TeleporterERC20Test is Test {
    TeleporterERC20 public token;
    address public teleporterMessenger;
    address public owner;
    address public user1;
    address public user2;

    bytes32 public constant CHAIN1_ID = bytes32(uint256(1));
    bytes32 public constant CHAIN2_ID = bytes32(uint256(2));
    bytes32 public constant MESSAGE_ID = bytes32(uint256(12345));

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Teleporter Messengerのモックアドレス
        teleporterMessenger = address(0x1000);

        // トークンをデプロイ
        token = new TeleporterERC20("Test Token", "TEST", teleporterMessenger);
    }

    /**
     * @dev mint機能のテスト
     */
    function testMint() public {
        uint256 amount = 1000 * 10 ** 18;

        // 誰でもmintできることを確認
        vm.prank(user1);
        token.mint(user1, amount);

        assertEq(token.balanceOf(user1), amount);
    }

    /**
     * @dev 複数ユーザーのmintテスト
     */
    function testMultipleUsersMint() public {
        uint256 amount1 = 500 * 10 ** 18;
        uint256 amount2 = 300 * 10 ** 18;

        vm.prank(user1);
        token.mint(user1, amount1);

        vm.prank(user2);
        token.mint(user2, amount2);

        assertEq(token.balanceOf(user1), amount1);
        assertEq(token.balanceOf(user2), amount2);
    }

    /**
     * @dev setTeleporterMessenger機能のテスト
     */
    function testSetTeleporterMessenger() public {
        address newMessenger = address(0x2000);

        // オーナーのみが設定できる
        token.setTeleporterMessenger(newMessenger);
        assertEq(address(token.teleporterMessenger()), newMessenger);
    }

    /**
     * @dev オーナー以外はTeleporter Messengerを設定できない
     */
    function testSetTeleporterMessengerNotOwner() public {
        address newMessenger = address(0x2000);

        vm.prank(user1);
        vm.expectRevert();
        token.setTeleporterMessenger(newMessenger);
    }

    /**
     * @dev sendTokensの成功ケース
     */
    function testSendTokensSuccess() public {
        uint256 amount = 100 * 10 ** 18;
        address destinationAddress = address(0x5000);
        address recipient = user2;

        // user1にトークンをmint
        vm.prank(user1);
        token.mint(user1, amount);

        // Teleporterの呼び出しをモック
        vm.mockCall(
            teleporterMessenger,
            abi.encodeWithSignature("sendCrossChainMessage((bytes32,address,(address,uint256),uint256,address[],bytes))"),
            abi.encode(MESSAGE_ID)
        );

        // トークンを送信
        vm.prank(user1);
        token.sendTokens(CHAIN2_ID, destinationAddress, recipient, amount);

        // トークンがburnされたことを確認
        assertEq(token.balanceOf(user1), 0);
    }

    /**
     * @dev sendTokensの失敗ケース：金額が0
     */
    function testSendTokensZeroAmount() public {
        address destinationAddress = address(0x5000);
        address recipient = user2;

        vm.prank(user1);
        vm.expectRevert("TeleporterERC20: zero amount");
        token.sendTokens(CHAIN2_ID, destinationAddress, recipient, 0);
    }

    /**
     * @dev receiveTeleporterMessageの失敗ケース：不正な呼び出し元
     */
    function testReceiveTeleporterMessageInvalidCaller() public {
        bytes memory payload = abi.encode(user1, 100 * 10 ** 18);

        vm.prank(user1);
        vm.expectRevert("TeleporterERC20: unauthorized");
        token.receiveTeleporterMessage(
            CHAIN2_ID,
            address(0x5000),
            payload
        );
    }

    /**
     * @dev receiveTeleporterMessageの成功ケース
     */
    function testReceiveTeleporterMessageSuccess() public {
        uint256 amount = 100 * 10 ** 18;
        bytes memory payload = abi.encode(user1, amount);

        // 正しいteleporterMessengerから呼び出す
        vm.prank(teleporterMessenger);
        token.receiveTeleporterMessage(
            CHAIN2_ID,
            address(0x5000),
            payload
        );

        // トークンがmintされたことを確認
        assertEq(token.balanceOf(user1), amount);
    }
}
