// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ITeleporterMessenger, TeleporterMessageInput, TeleporterFeeInfo} from "@avalabs/teleporter/ITeleporterMessenger.sol";

/**
 * @title SimpleSender
 * @dev シンプルなTeleporterメッセージ送信テスト用コントラクト
 */
contract SimpleSender {
    ITeleporterMessenger public immutable teleporterMessenger;

    event MessageSent(
        bytes32 indexed destinationChainID,
        address indexed destinationAddress,
        string message
    );

    constructor(address _teleporterMessenger) {
        require(
            _teleporterMessenger != address(0),
            "SimpleSender: zero address"
        );
        teleporterMessenger = ITeleporterMessenger(_teleporterMessenger);
    }

    /**
     * @dev メッセージを他のチェーンに送信
     * @param destinationChainID 送信先チェーンID
     * @param destinationAddress 受信側コントラクトアドレス
     * @param message 送信するメッセージ
     */
    function sendMessage(
        bytes32 destinationChainID,
        address destinationAddress,
        string calldata message
    ) external {
        teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: destinationChainID,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({
                    feeTokenAddress: address(0),
                    amount: 0
                }),
                requiredGasLimit: 200000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message)
            })
        );

        emit MessageSent(destinationChainID, destinationAddress, message);
    }
}
