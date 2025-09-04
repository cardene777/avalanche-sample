// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/SimpleReceiver.sol";
import "@avalabs/teleporter/ITeleporterMessenger.sol";

/**
 * @title SimpleReceiverテストコントラクト
 */
contract SimpleReceiverTest is Test {
    SimpleReceiver public receiver;
    address public teleporterMessenger;
    address public user1;
    
    bytes32 public constant ORIGIN_CHAIN_ID = bytes32(uint256(1));
    address public constant ORIGIN_SENDER_ADDRESS = address(0x5000);
    
    function setUp() public {
        user1 = address(0x1);
        
        // Teleporter Messengerのモックアドレス
        teleporterMessenger = address(0x1000);
        
        // SimpleReceiverをデプロイ
        receiver = new SimpleReceiver(teleporterMessenger);
    }
    
    /**
     * @dev メッセージ受信の成功テスト
     */
    function testReceiveMessageSuccess() public {
        string memory message = "Hello from sender!";
        bytes memory encodedMessage = abi.encode(message);
        
        // イベントの発行を確認
        vm.expectEmit(true, true, false, true);
        emit SimpleReceiver.MessageReceived(ORIGIN_CHAIN_ID, ORIGIN_SENDER_ADDRESS, message);
        
        // Teleporter Messengerからメッセージを受信
        vm.prank(teleporterMessenger);
        receiver.receiveTeleporterMessage(
            ORIGIN_CHAIN_ID,
            ORIGIN_SENDER_ADDRESS,
            encodedMessage
        );
        
        // 状態変数が正しく更新されたことを確認
        assertEq(receiver.lastMessage(), message);
        assertEq(receiver.lastSender(), ORIGIN_SENDER_ADDRESS);
        assertEq(receiver.lastOriginChainID(), ORIGIN_CHAIN_ID);
    }
    
    /**
     * @dev 不正な呼び出し元からの受信失敗テスト
     */
    function testReceiveMessageUnauthorized() public {
        string memory message = "Unauthorized message";
        bytes memory encodedMessage = abi.encode(message);
        
        // 不正な呼び出し元からの受信は失敗する
        vm.prank(user1);
        vm.expectRevert("SimpleReceiver: unauthorized");
        receiver.receiveTeleporterMessage(
            ORIGIN_CHAIN_ID,
            ORIGIN_SENDER_ADDRESS,
            encodedMessage
        );
    }
    
    /**
     * @dev 複数メッセージの連続受信テスト
     */
    function testReceiveMultipleMessages() public {
        string[3] memory messages = ["First message", "Second message", "Third message"];
        
        for (uint i = 0; i < messages.length; i++) {
            bytes memory encodedMessage = abi.encode(messages[i]);
            
            vm.prank(teleporterMessenger);
            receiver.receiveTeleporterMessage(
                ORIGIN_CHAIN_ID,
                ORIGIN_SENDER_ADDRESS,
                encodedMessage
            );
            
            // 最新のメッセージが保存されていることを確認
            assertEq(receiver.lastMessage(), messages[i]);
        }
    }
    
    /**
     * @dev 空文字列の受信テスト
     */
    function testReceiveEmptyMessage() public {
        string memory emptyMessage = "";
        bytes memory encodedMessage = abi.encode(emptyMessage);
        
        vm.prank(teleporterMessenger);
        receiver.receiveTeleporterMessage(
            ORIGIN_CHAIN_ID,
            ORIGIN_SENDER_ADDRESS,
            encodedMessage
        );
        
        assertEq(receiver.lastMessage(), emptyMessage);
    }
    
    /**
     * @dev 異なるチェーンIDからの受信テスト
     */
    function testReceiveFromDifferentChains() public {
        bytes32[3] memory chainIds = [
            bytes32(uint256(1)),
            bytes32(uint256(2)),
            bytes32(uint256(3))
        ];
        
        for (uint i = 0; i < chainIds.length; i++) {
            string memory message = string(abi.encodePacked("Message from chain ", uint256(chainIds[i])));
            bytes memory encodedMessage = abi.encode(message);
            
            vm.prank(teleporterMessenger);
            receiver.receiveTeleporterMessage(
                chainIds[i],
                ORIGIN_SENDER_ADDRESS,
                encodedMessage
            );
            
            assertEq(receiver.lastOriginChainID(), chainIds[i]);
        }
    }
    
    /**
     * @dev 長いメッセージの受信テスト
     */
    function testReceiveLongMessage() public {
        // 1000文字の長いメッセージ
        bytes memory longBytes = new bytes(1000);
        for (uint i = 0; i < 1000; i++) {
            longBytes[i] = bytes1(uint8(65 + (i % 26))); // A-Z
        }
        string memory longMessage = string(longBytes);
        bytes memory encodedMessage = abi.encode(longMessage);
        
        vm.prank(teleporterMessenger);
        receiver.receiveTeleporterMessage(
            ORIGIN_CHAIN_ID,
            ORIGIN_SENDER_ADDRESS,
            encodedMessage
        );
        
        assertEq(receiver.lastMessage(), longMessage);
    }
}