// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/console.sol";
import {ERC20TokenHome} from "../src/ictt/TokenHome/ERC20TokenHome.sol";
import {Config} from "./Config.sol";

/**
 * @title DeployTokenHome
 * @notice ERC20TokenHome（送信元チェーン側）をデプロイするスクリプト
 * @dev 使用方法:
 *      forge script script/DeployTokenHome.s.sol:DeployTokenHome \
 *        --rpc-url $FUJI_RPC_URL \
 *        --private-key $PRIVATE_KEY \
 *        --broadcast
 *
 * @dev 必要な環境変数:
 *      - TELEPORTER_REGISTRY_ADDRESS: TeleporterRegistryのアドレス
 *      - TOKEN_ADDRESS: ブリッジするERC20トークンのアドレス
 *      - TOKEN_DECIMALS: トークンのdecimals（デフォルト: 18）
 */
contract DeployTokenHome is Script, Config {
    /**
     * @notice デプロイメインロジック
     */
    function run() external {
        // 環境変数から必要なパラメータを取得
        address teleporterRegistry = vm.envAddress("TELEPORTER_REGISTRY_ADDRESS");
        address teleporterManager = vm.envOr("TELEPORTER_MANAGER", msg.sender);
        uint256 minTeleporterVersion = vm.envOr("MIN_TELEPORTER_VERSION", uint256(1));
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        uint8 tokenDecimals = uint8(vm.envOr("TOKEN_DECIMALS", uint256(18)));

        console.log(unicode"=== ERC20TokenHome デプロイ開始 ===");
        console.log("Deployer:", msg.sender);
        console.log("Teleporter Registry:", teleporterRegistry);
        console.log("Teleporter Manager:", teleporterManager);
        console.log("Min Teleporter Version:", minTeleporterVersion);
        console.log("Token Address:", tokenAddress);
        console.log("Token Decimals:", tokenDecimals);

        // デプロイ実行
        vm.startBroadcast();

        ERC20TokenHome tokenHome = new ERC20TokenHome(
            teleporterRegistry,
            teleporterManager,
            minTeleporterVersion,
            tokenAddress,
            tokenDecimals
        );

        vm.stopBroadcast();

        // デプロイ結果の表示
        console.log("");
        console.log(unicode"=== デプロイ完了 ===");
        console.log("ERC20TokenHome Address:", address(tokenHome));
        console.log("Blockchain ID:", vm.toString(tokenHome.getBlockchainID()));
        console.log("");
        console.log(unicode"次のステップ:");
        console.log(unicode"1. Dispatch TestnetにERC20TokenRemoteをデプロイ");
        console.log(unicode"2. RegisterRemote.s.solでリモートチェーンを登録");
        console.log(unicode"3. SendTokens.s.solでトークンを送信");
    }
}
