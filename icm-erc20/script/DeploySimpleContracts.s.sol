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
    address constant TELEPORTER_MESSENGER = 0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf;
    
    function run() external {
        // デプロイ用の秘密鍵を取得
        uint256 deployerPrivateKey = vm.envUint("PK");
        string memory contractType = vm.envString("CONTRACT_TYPE");
        
        vm.startBroadcast(deployerPrivateKey);
        
        if (keccak256(bytes(contractType)) == keccak256(bytes("sender"))) {
            // SimpleSenderをデプロイ
            SimpleSender sender = new SimpleSender(TELEPORTER_MESSENGER);
            console.log("SimpleSender deployed to:", address(sender));
        } else if (keccak256(bytes(contractType)) == keccak256(bytes("receiver"))) {
            // SimpleReceiverをデプロイ
            SimpleReceiver receiver = new SimpleReceiver(TELEPORTER_MESSENGER);
            console.log("SimpleReceiver deployed to:", address(receiver));
        } else {
            revert("Unknown contract type. Use 'sender' or 'receiver'");
        }
        
        vm.stopBroadcast();
    }
}