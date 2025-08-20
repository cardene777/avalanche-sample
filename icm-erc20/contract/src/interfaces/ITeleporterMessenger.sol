// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * TeleporterMessengerインターフェース
 * Avalanche ICMでのメッセージ送受信を行うためのインターフェース
 */
interface ITeleporterMessenger {
    struct TeleporterMessage {
        bytes32 messageID;
        address senderAddress;
        bytes32 destinationBlockchainID;
        address destinationAddress;
        uint256 requiredGasLimit;
        address[] allowedRelayerAddresses;
        TeleporterMessageReceipt[] receipts;
        bytes message;
    }

    struct TeleporterMessageReceipt {
        bytes32 receivedMessageID;
        address relayerRewardAddress;
    }

    struct TeleporterFeeInfo {
        address feeTokenAddress;
        uint256 amount;
    }

    function sendCrossChainMessage(
        TeleporterMessageInput calldata messageInput
    ) external returns (bytes32 messageID);

    function receiveCrossChainMessage(
        uint32 messageIndex,
        address relayerRewardAddress
    ) external;

    function getMessageHash(
        bytes32 messageID
    ) external view returns (bytes32);

    function messageReceived(
        bytes32 messageID
    ) external view returns (bool);

    struct TeleporterMessageInput {
        bytes32 destinationBlockchainID;
        address destinationAddress;
        TeleporterFeeInfo feeInfo;
        uint256 requiredGasLimit;
        address[] allowedRelayerAddresses;
        bytes message;
    }
}