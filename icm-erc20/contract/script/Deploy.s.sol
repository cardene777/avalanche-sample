// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TeleporterERC20} from "../src/TeleporterERC20.sol";

/**
 * ERC20トークンのデプロイスクリプト
 */
contract DeployScript is Script {
    // Teleporter Messenger Address (固定)
    address constant TELEPORTER_MESSENGER = 0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf;

    function run() external {
        // 環境変数から設定を読み込む
        string memory tokenName = vm.envString("TOKEN_NAME");
        string memory tokenSymbol = vm.envString("TOKEN_SYMBOL");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // デプロイ開始
        vm.startBroadcast(deployerPrivateKey);

        // ERC20トークンをデプロイ
        TeleporterERC20 token = new TeleporterERC20(
            tokenName,
            tokenSymbol,
            TELEPORTER_MESSENGER
        );

        // デプロイ情報を出力
        vm.stopBroadcast();

        // デプロイ結果を表示
        console.log("Token deployed at:", address(token));
        console.log("Token name:", tokenName);
        console.log("Token symbol:", tokenSymbol);
    }
}