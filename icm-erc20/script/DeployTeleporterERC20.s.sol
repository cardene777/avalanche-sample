// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/TeleporterERC20.sol";

/**
 * @title TeleporterERC20デプロイスクリプト
 */
contract DeployTeleporterERC20Script is Script {
    // Teleporter Messengerアドレス（Fujiテストネット共通）
    address constant TELEPORTER_MESSENGER_FUJI = 0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf;
    
    function run() external {
        // デプロイ用の秘密鍵を取得
        // DEPLOY_PKが設定されていればそれを使用、なければPKを使用
        uint256 deployerPrivateKey;
        try vm.envUint("DEPLOY_PK") returns (uint256 pk) {
            deployerPrivateKey = pk;
        } catch {
            deployerPrivateKey = vm.envUint("PK");
        }
        
        // チェーンIDに基づいてトークン名とシンボルを設定
        string memory tokenName;
        string memory tokenSymbol;
        address teleporterMessenger;
        string memory chainName = vm.envString("CHAIN_NAME");
        
        if (keccak256(bytes(chainName)) == keccak256(bytes("fuji-c"))) {
            tokenName = "FujiCToken";
            tokenSymbol = "FCT";
            teleporterMessenger = TELEPORTER_MESSENGER_FUJI;
        } else if (keccak256(bytes(chainName)) == keccak256(bytes("fuji-dispatch"))) {
            tokenName = "FujiDispatchToken";
            tokenSymbol = "FDT";
            teleporterMessenger = TELEPORTER_MESSENGER_FUJI;
        } else if (keccak256(bytes(chainName)) == keccak256(bytes("local-l1"))) {
            tokenName = "LocalL1Token";
            tokenSymbol = "L1T";
            // ローカル環境では実際のTeleporter Messengerアドレスを使用
            // Avalancheローカルノードのデフォルト値
            teleporterMessenger = 0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf;
        } else if (keccak256(bytes(chainName)) == keccak256(bytes("local-l2"))) {
            tokenName = "LocalL2Token";
            tokenSymbol = "L2T";
            // ローカル環境では実際のTeleporter Messengerアドレスを使用
            // Avalancheローカルノードのデフォルト値
            teleporterMessenger = 0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf;
        } else {
            revert("Unknown chain name");
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // TeleporterERC20をデプロイ
        TeleporterERC20 token = new TeleporterERC20(
            tokenName,
            tokenSymbol,
            teleporterMessenger
        );
        
        vm.stopBroadcast();
        
        // デプロイしたアドレスを出力
        console.log("TeleporterERC20 deployed to:", address(token));
    }
}