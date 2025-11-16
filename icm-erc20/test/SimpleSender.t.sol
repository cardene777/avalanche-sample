// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/SimpleSender.sol";
import "@avalabs/teleporter/ITeleporterMessenger.sol";

/**
 * @title SimpleSenderテストコントラクト
 */
contract SimpleSenderTest is Test {
    SimpleSender public sender;
    address public teleporterMessenger;
    address public user1;
    
    bytes32 public constant DESTINATION_CHAIN_ID = bytes32(uint256(2));
    address public constant DESTINATION_ADDRESS = address(0x5000);
    bytes32 public constant MESSAGE_ID = bytes32(uint256(12345));
    
    function setUp() public {
        user1 = address(0x1);
        
        // Teleporter Messengerのモックアドレス
        teleporterMessenger = address(0x1000);
        
        // SimpleSenderをデプロイ
        sender = new SimpleSender(teleporterMessenger);
    }
    
    /**
     * @dev メッセージ送信の成功テスト
     */
    function testSendMessageSuccess() public {
        string memory message = "Hello from test!";
        
        // Teleporterの呼び出しをモック
        vm.mockCall(
            teleporterMessenger,
            abi.encodeWithSignature("sendCrossChainMessage((bytes32,address,(address,uint256),uint256,address[],bytes))"),
            abi.encode(MESSAGE_ID)
        );
        
        // イベントの発行を確認
        vm.expectEmit(true, true, false, true);
        emit SimpleSender.MessageSent(DESTINATION_CHAIN_ID, DESTINATION_ADDRESS, message);
        
        // メッセージを送信
        vm.prank(user1);
        sender.sendMessage(DESTINATION_CHAIN_ID, DESTINATION_ADDRESS, message);
    }
    
    /**
     * @dev 複数のメッセージ送信テスト
     */
    function testSendMultipleMessages() public {
        string[3] memory messages = ["Message 1", "Message 2", "Message 3"];
        
        // Teleporterの呼び出しをモック
        vm.mockCall(
            teleporterMessenger,
            abi.encodeWithSignature("sendCrossChainMessage((bytes32,address,(address,uint256),uint256,address[],bytes))"),
            abi.encode(MESSAGE_ID)
        );
        
        // 複数のメッセージを送信
        for (uint i = 0; i < messages.length; i++) {
            vm.expectEmit(true, true, false, true);
            emit SimpleSender.MessageSent(DESTINATION_CHAIN_ID, DESTINATION_ADDRESS, messages[i]);
            
            vm.prank(user1);
            sender.sendMessage(DESTINATION_CHAIN_ID, DESTINATION_ADDRESS, messages[i]);
        }
    }
    
    /**
     * @dev 空文字列の送信テスト
     */
    function testSendEmptyMessage() public {
        string memory message = "";
        
        // Teleporterの呼び出しをモック
        vm.mockCall(
            teleporterMessenger,
            abi.encodeWithSignature("sendCrossChainMessage((bytes32,address,(address,uint256),uint256,address[],bytes))"),
            abi.encode(MESSAGE_ID)
        );
        
        // 空文字列でも送信できることを確認
        vm.expectEmit(true, true, false, true);
        emit SimpleSender.MessageSent(DESTINATION_CHAIN_ID, DESTINATION_ADDRESS, message);
        
        vm.prank(user1);
        sender.sendMessage(DESTINATION_CHAIN_ID, DESTINATION_ADDRESS, message);
    }
    
    /**
     * @dev 長いメッセージの送信テスト
     */
    function testSendLongMessage() public {
        // 1000文字の長いメッセージ
        bytes memory longBytes = new bytes(1000);
        for (uint i = 0; i < 1000; i++) {
            longBytes[i] = bytes1(uint8(65 + (i % 26))); // A-Z
        }
        string memory longMessage = string(longBytes);
        
        // Teleporterの呼び出しをモック
        vm.mockCall(
            teleporterMessenger,
            abi.encodeWithSignature("sendCrossChainMessage((bytes32,address,(address,uint256),uint256,address[],bytes))"),
            abi.encode(MESSAGE_ID)
        );
        
        // 長いメッセージも送信できることを確認
        vm.expectEmit(true, true, false, true);
        emit SimpleSender.MessageSent(DESTINATION_CHAIN_ID, DESTINATION_ADDRESS, longMessage);
        
        vm.prank(user1);
        sender.sendMessage(DESTINATION_CHAIN_ID, DESTINATION_ADDRESS, longMessage);
    }
}