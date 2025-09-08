// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/SimpleSender.sol";
import "../src/SimpleReceiver.sol";

/**
 * @title SimpleSenderとSimpleReceiverのデプロイスクリプト
 */
contract DeploySimpleContractsScript is Script {
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
        string memory contractType = vm.envString("CONTRACT_TYPE");
        
        // ICM Registryアドレスを決定
        address teleporterMessenger;
        
        // 環境に応じてICM Registryアドレスを設定
        // 環境変数CHAIN_NAMEがあればそれを使用、なければRPC URLから判断
        try vm.envString("CHAIN_NAME") returns (string memory chainName) {
            if (keccak256(bytes(chainName)) == keccak256(bytes("local-l1"))) {
                // ローカル環境では実際のTeleporter Messengerアドレスを使用
                teleporterMessenger = 0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf;
            } else if (keccak256(bytes(chainName)) == keccak256(bytes("local-l2"))) {
                // ローカル環境では実際のTeleporter Messengerアドレスを使用
                teleporterMessenger = 0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf;
            } else {
                teleporterMessenger = TELEPORTER_MESSENGER_FUJI;
            }
        } catch {
            // CHAIN_NAMEが設定されていない場合は、Fujiと仮定
            teleporterMessenger = TELEPORTER_MESSENGER_FUJI;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        if (keccak256(bytes(contractType)) == keccak256(bytes("sender"))) {
            // SimpleSenderをデプロイ
            SimpleSender sender = new SimpleSender(teleporterMessenger);
            console.log("SimpleSender deployed to:", address(sender));
        } else if (keccak256(bytes(contractType)) == keccak256(bytes("receiver"))) {
            // SimpleReceiverをデプロイ
            SimpleReceiver receiver = new SimpleReceiver(teleporterMessenger);
            console.log("SimpleReceiver deployed to:", address(receiver));
        } else {
            revert("Unknown contract type. Use 'sender' or 'receiver'");
        }
        
        vm.stopBroadcast();
    }
}