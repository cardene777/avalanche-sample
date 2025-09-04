// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ITeleporterReceiver} from "@avalabs/teleporter/ITeleporterReceiver.sol";
import {ITeleporterMessenger} from "@avalabs/teleporter/ITeleporterMessenger.sol";

/**
 * @title SimpleReceiver
 * @dev シンプルなTeleporterメッセージ受信テスト用コントラクト
 */
contract SimpleReceiver is ITeleporterReceiver {
    ITeleporterMessenger public immutable teleporterMessenger;

    string public lastMessage;
    address public lastSender;
    bytes32 public lastOriginChainID;

    event MessageReceived(
        bytes32 indexed originChainID,
        address indexed originSenderAddress,
        string message
    );

    modifier onlyTeleporter() {
        require(
            msg.sender == address(teleporterMessenger),
            "SimpleReceiver: unauthorized"
        );
        _;
    }

    constructor(address _teleporterMessenger) {
        require(
            _teleporterMessenger != address(0),
            "SimpleReceiver: zero address"
        );
        teleporterMessenger = ITeleporterMessenger(_teleporterMessenger);
    }

    /**
     * @dev Teleporterからメッセージを受信
     * @param originChainID ソースチェーンID
     * @param originSenderAddress 送信元アドレス
     * @param message メッセージペイロード
     */
    function receiveTeleporterMessage(
        bytes32 originChainID,
        address originSenderAddress,
        bytes calldata message
    ) external onlyTeleporter {
        string memory decodedMessage = abi.decode(message, (string));

        lastMessage = decodedMessage;
        lastSender = originSenderAddress;
        lastOriginChainID = originChainID;

        emit MessageReceived(
            originChainID,
            originSenderAddress,
            decodedMessage
        );
    }
}
