// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/console.sol";
import {ERC20TokenRemote} from "../src/ictt/TokenRemote/ERC20TokenRemote.sol";
import {TokenRemoteSettings} from "../src/ictt/TokenRemote/interfaces/ITokenRemote.sol";
import {Config} from "./Config.sol";

/**
 * @title DeployTokenRemote
 * @notice ERC20TokenRemote（受信先チェーン側）をデプロイするスクリプト
 * @dev 使用方法:
 *      forge script script/DeployTokenRemote.s.sol:DeployTokenRemote \
 *        --rpc-url $DISPATCH_RPC_URL \
 *        --private-key $PRIVATE_KEY \
 *        --broadcast
 *
 * @dev 必要な環境変数:
 *      - TELEPORTER_REGISTRY_ADDRESS: TeleporterRegistryのアドレス
 *      - TOKEN_HOME_BLOCKCHAIN_ID: TokenHomeのブロックチェーンID
 *      - TOKEN_HOME_ADDRESS: TokenHomeコントラクトのアドレス
 *      - TOKEN_HOME_DECIMALS: TokenHome側のトークンdecimals
 *      - REMOTE_TOKEN_NAME: Remoteトークンの名前（デフォルト: "Bridged Token"）
 *      - REMOTE_TOKEN_SYMBOL: Remoteトークンのシンボル（デフォルト: "BRDG"）
 *      - REMOTE_TOKEN_DECIMALS: Remoteトークンのdecimals（デフォルト: 18）
 */
contract DeployTokenRemote is Script, Config {
    /**
     * @notice デプロイメインロジック
     */
    function run() external {
        // 環境変数から必要なパラメータを取得
        address teleporterRegistry = vm.envAddress("TELEPORTER_REGISTRY_ADDRESS");
        address teleporterManager = vm.envOr("TELEPORTER_MANAGER", msg.sender);
        uint256 minTeleporterVersion = vm.envOr("MIN_TELEPORTER_VERSION", uint256(1));
        bytes32 tokenHomeBlockchainID = vm.envBytes32("TOKEN_HOME_BLOCKCHAIN_ID");
        address tokenHomeAddress = vm.envAddress("TOKEN_HOME_ADDRESS");
        uint8 tokenHomeDecimals = uint8(vm.envOr("TOKEN_HOME_DECIMALS", uint256(18)));

        string memory remoteTokenName = vm.envOr("REMOTE_TOKEN_NAME", string("Bridged Token"));
        string memory remoteTokenSymbol = vm.envOr("REMOTE_TOKEN_SYMBOL", string("BRDG"));
        uint8 remoteTokenDecimals = uint8(vm.envOr("REMOTE_TOKEN_DECIMALS", uint256(18)));

        console.log(unicode"=== ERC20TokenRemote デプロイ開始 ===");
        console.log("Deployer:", msg.sender);
        console.log("Teleporter Registry:", teleporterRegistry);
        console.log("Teleporter Manager:", teleporterManager);
        console.log("Min Teleporter Version:", minTeleporterVersion);
        console.log("Token Home Blockchain ID:", vm.toString(tokenHomeBlockchainID));
        console.log("Token Home Address:", tokenHomeAddress);
        console.log("Token Home Decimals:", tokenHomeDecimals);
        console.log("Remote Token Name:", remoteTokenName);
        console.log("Remote Token Symbol:", remoteTokenSymbol);
        console.log("Remote Token Decimals:", remoteTokenDecimals);

        // TokenRemoteSettingsの構築
        TokenRemoteSettings memory settings = TokenRemoteSettings({
            teleporterRegistryAddress: teleporterRegistry,
            teleporterManager: teleporterManager,
            minTeleporterVersion: minTeleporterVersion,
            tokenHomeBlockchainID: tokenHomeBlockchainID,
            tokenHomeAddress: tokenHomeAddress,
            tokenHomeDecimals: tokenHomeDecimals
        });

        // デプロイ実行
        vm.startBroadcast();

        ERC20TokenRemote tokenRemote = new ERC20TokenRemote(
            settings,
            remoteTokenName,
            remoteTokenSymbol,
            remoteTokenDecimals
        );

        vm.stopBroadcast();

        // デプロイ結果の表示
        console.log("");
        console.log(unicode"=== デプロイ完了 ===");
        console.log("ERC20TokenRemote Address:", address(tokenRemote));
        console.log("Blockchain ID:", vm.toString(tokenRemote.getBlockchainID()));
        console.log("Token Name:", tokenRemote.name());
        console.log("Token Symbol:", tokenRemote.symbol());
        console.log("Token Decimals:", tokenRemote.decimals());
        console.log("");
        console.log(unicode"次のステップ:");
        console.log(unicode"1. TokenHomeでこのリモートチェーンを登録（RegisterRemote.s.sol）");
        console.log(unicode"2. トークンを送信（SendTokens.s.sol）");
    }
}
