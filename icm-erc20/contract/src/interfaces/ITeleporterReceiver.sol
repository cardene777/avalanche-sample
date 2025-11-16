// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * TeleporterReceiverインターフェース
 * Teleporterメッセージを受信するコントラクトが実装すべきインターフェース
 */
interface ITeleporterReceiver {
    /**
     * Teleporterメッセージを受信する
     * @param teleporterMessageID メッセージID
     * @param originSenderAddress 送信元アドレス
     * @param message メッセージデータ
     */
    function receiveTeleporterMessage(
        bytes32 teleporterMessageID,
        bytes32 originChainID,
        address originSenderAddress,
        bytes calldata message
    ) external;
}