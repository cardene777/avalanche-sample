// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

/**
 * @title Config
 * @notice ネットワーク設定を管理するコントラクト
 * @dev Home/Remote チェーンの設定を提供
 */
contract Config {
    /**
     * @notice Homeチェーン（トークン発行元）の設定
     */
    struct HomeConfig {
        address teleporterRegistry;
        address teleporterMessenger;
        bytes32 blockchainID;
        uint256 chainId;
    }

    /**
     * @notice Remoteチェーン（転送先）の設定
     */
    struct RemoteConfig {
        address teleporterRegistry;
        address teleporterMessenger;
        bytes32 blockchainID;
        uint256 chainId;
    }

    /**
     * @notice Homeチェーンの設定を取得
     * @dev 実際のアドレスは環境変数から設定
     */
    function getHomeConfig() internal pure returns (HomeConfig memory) {
        return HomeConfig({
            teleporterRegistry: address(0), // .envから設定
            teleporterMessenger: address(0), // .envから設定
            blockchainID: bytes32(0), // .envから設定
            chainId: 0 // .envから設定
        });
    }

    /**
     * @notice Remoteチェーンの設定を取得
     * @dev 実際のアドレスは環境変数から設定
     */
    function getRemoteConfig() internal pure returns (RemoteConfig memory) {
        return RemoteConfig({
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
