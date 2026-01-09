// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

/**
 * @title Config
 * @notice テストネットワーク設定を管理するコントラクト
 * @dev Fuji C-ChainとDispatch Testnetの設定を提供
 */
contract Config {
    /**
     * @notice Fuji C-Chain（Avalanche テストネット）の設定
     */
    struct FujiConfig {
        address teleporterRegistry;
        address teleporterMessenger;
        bytes32 blockchainID;
        uint256 chainId;
    }

    /**
     * @notice Dispatch Testnetの設定
     */
    struct DispatchConfig {
        address teleporterRegistry;
        address teleporterMessenger;
        bytes32 blockchainID;
        uint256 chainId;
    }

    /**
     * @notice Fuji C-Chainの設定を取得
     * @dev Teleporter Registry: 0x827364Da64e8f8466c23520d81731e94c8DDe510（仮）
     * @dev 実際のアドレスは環境変数またはデプロイ時に設定
     */
    function getFujiConfig() internal pure returns (FujiConfig memory) {
        return FujiConfig({
            teleporterRegistry: address(0), // .envから設定
            teleporterMessenger: address(0), // .envから設定
            blockchainID: bytes32(0), // .envから設定
            chainId: 43113 // Fuji C-Chain
        });
    }

    /**
     * @notice Dispatch Testnetの設定を取得
     * @dev 実際のアドレスは環境変数またはデプロイ時に設定
     */
    function getDispatchConfig() internal pure returns (DispatchConfig memory) {
        return DispatchConfig({
            teleporterRegistry: address(0), // .envから設定
            teleporterMessenger: address(0), // .envから設定
            blockchainID: bytes32(0), // .envから設定
            chainId: 0 // .envから設定
        });
    }

    /**
     * @notice デフォルトのトークン設定
     */
    struct TokenConfig {
        string name;
        string symbol;
        uint8 decimals;
        uint256 initialSupply;
    }

    /**
     * @notice デフォルトのトークン設定を取得
     */
    function getDefaultTokenConfig() internal pure returns (TokenConfig memory) {
        return TokenConfig({
            name: "Sample Token",
            symbol: "SMPL",
            decimals: 18,
            initialSupply: 1000000 * 10 ** 18 // 100万トークン
        });
    }
}
