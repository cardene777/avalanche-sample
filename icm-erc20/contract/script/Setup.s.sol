// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TeleporterERC20} from "../src/TeleporterERC20.sol";

/**
 * リモートトークンアドレスの設定スクリプト
 * Chain1とChain2の相互設定を行う
 */
contract SetupScript is Script {
    function run() external {
        // 環境変数から設定を読み込む
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Chain1の設定
        address chain1Token = vm.envAddress("CHAIN1_TOKEN_ADDRESS");
        bytes32 chain1BlockchainId = vm.envBytes32("CHAIN1_BLOCKCHAIN_ID");
        
        // Chain2の設定
        address chain2Token = vm.envAddress("CHAIN2_TOKEN_ADDRESS");
        bytes32 chain2BlockchainId = vm.envBytes32("CHAIN2_BLOCKCHAIN_ID");
        
        // 現在実行中のチェーンを判定（RPC URLまたはチェーンIDで判定）
        uint256 chainId = block.chainid;
        
        vm.startBroadcast(deployerPrivateKey);
        
        if (chainId == 5001) {
            // Chain1で実行中: Chain2のトークンアドレスを設定
            TeleporterERC20(chain1Token).setRemoteTokenAddress(
                chain2BlockchainId,
                chain2Token
            );
            console.log("Chain1: Set remote token address");
            console.log("Local token:", chain1Token);
            console.log("Remote blockchain ID:", vm.toString(chain2BlockchainId));
            console.log("Remote token:", chain2Token);
        } else if (chainId == 5002) {
            // Chain2で実行中: Chain1のトークンアドレスを設定
            TeleporterERC20(chain2Token).setRemoteTokenAddress(
                chain1BlockchainId,
                chain1Token
            );
            console.log("Chain2: Set remote token address");
            console.log("Local token:", chain2Token);
            console.log("Remote blockchain ID:", vm.toString(chain1BlockchainId));
            console.log("Remote token:", chain1Token);
        } else {
            revert("Unknown chain ID. Expected 5001 or 5002");
        }
        
        vm.stopBroadcast();
    }
}