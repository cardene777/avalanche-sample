// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/TeleporterERC20.sol";

/**
 * TeleporterERC20をデプロイするスクリプト
 */
contract DeployTeleporterERC20 is Script {
    function run() external {
        // デプロイヤーの秘密鍵を取得
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // TeleporterMessengerのアドレス（既知のアドレス）
        address teleporterMessenger = 0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf;
        
        // デプロイ開始
        vm.startBroadcast(deployerPrivateKey);
        
        // TeleporterERC20をデプロイ
        TeleporterERC20 token = new TeleporterERC20(
            "MyToken",        // トークン名
            "MTK",           // シンボル
            teleporterMessenger
        );
        
        vm.stopBroadcast();
        
        // デプロイ結果を表示
        console.log("TeleporterERC20 deployed at:", address(token));
        console.log("Owner:", token.owner());
        console.log("Teleporter Messenger:", address(token.teleporterMessenger()));
    }
}