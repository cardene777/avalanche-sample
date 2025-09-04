// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/TeleporterERC20.sol";

/**
 * @title TeleporterERC20デプロイスクリプト
 */
contract DeployTeleporterERC20Script is Script {
    // Teleporter Messengerアドレス（Fujiテストネット共通）
    address constant TELEPORTER_MESSENGER = 0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf;
    
    function run() external {
        // デプロイ用の秘密鍵を取得
        uint256 deployerPrivateKey = vm.envUint("PK");
        
        // チェーンIDに基づいてトークン名とシンボルを設定
        string memory tokenName;
        string memory tokenSymbol;
        string memory chainName = vm.envString("CHAIN_NAME");
        
        if (keccak256(bytes(chainName)) == keccak256(bytes("fuji-c"))) {
            tokenName = "FujiCToken";
            tokenSymbol = "FCT";
        } else if (keccak256(bytes(chainName)) == keccak256(bytes("fuji-dispatch"))) {
            tokenName = "FujiDispatchToken";
            tokenSymbol = "FDT";
        } else {
            revert("Unknown chain name");
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // TeleporterERC20をデプロイ
        TeleporterERC20 token = new TeleporterERC20(
            tokenName,
            tokenSymbol,
            TELEPORTER_MESSENGER
        );
        
        vm.stopBroadcast();
        
        // デプロイしたアドレスを出力
        console.log("TeleporterERC20 deployed to:", address(token));
    }
}