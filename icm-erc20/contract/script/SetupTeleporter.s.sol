// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/TeleporterERC20.sol";

/**
 * TeleporterERC20の相互接続を設定するスクリプト
 */
contract SetupTeleporter is Script {
    function run() external {
        // デプロイヤーの秘密鍵を取得
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 環境変数から設定を取得
        address chain1Token = vm.envAddress("CHAIN1_TOKEN_ADDRESS");
        address chain2Token = vm.envAddress("CHAIN2_TOKEN_ADDRESS");
        bytes32 chain1ID = vm.envBytes32("CHAIN1_BLOCKCHAIN_ID");
        bytes32 chain2ID = vm.envBytes32("CHAIN2_BLOCKCHAIN_ID");
        
        // 現在のチェーンのRPCから判断してどちらのセットアップをするか決定
        string memory currentRPC = vm.envString("ETH_RPC_URL");
        string memory chain1RPC = vm.envString("CHAIN1_RPC_URL");
        
        vm.startBroadcast(deployerPrivateKey);
        
        if (keccak256(bytes(currentRPC)) == keccak256(bytes(chain1RPC))) {
            // Chain1のセットアップ
            console.log("Setting up Chain1 token");
            TeleporterERC20 token = TeleporterERC20(chain1Token);
            token.setRemoteTokenAddress(chain2ID, chain2Token);
            console.log("Chain1 token configured to connect with Chain2");
        } else {
            // Chain2のセットアップ
            console.log("Setting up Chain2 token");
            TeleporterERC20 token = TeleporterERC20(chain2Token);
            token.setRemoteTokenAddress(chain1ID, chain1Token);
            console.log("Chain2 token configured to connect with Chain1");
        }
        
        vm.stopBroadcast();
    }
}