// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TeleporterERC20} from "../src/TeleporterERC20.sol";

/**
 * クロスチェーン転送スクリプト
 * 現在のチェーンから相手チェーンへ転送
 */
contract TransferScript is Script {
    function run() external {
        // 環境変数から設定を読み込む
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // デフォルト値
        address sender = 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC;
        address recipient = 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC;
        uint256 amount = 100 ether;
        
        // Chain1とChain2の設定
        address chain1Token = vm.envAddress("CHAIN1_TOKEN_ADDRESS");
        address chain2Token = vm.envAddress("CHAIN2_TOKEN_ADDRESS");
        bytes32 chain1BlockchainId = vm.envBytes32("CHAIN1_BLOCKCHAIN_ID");
        bytes32 chain2BlockchainId = vm.envBytes32("CHAIN2_BLOCKCHAIN_ID");
        
        // 現在実行中のチェーンを判定
        uint256 chainId = block.chainid;
        
        address tokenAddress;
        bytes32 destinationBlockchainId;
        string memory sourceChain;
        string memory destChain;
        
        if (chainId == 5001) {
            // Chain1から Chain2へ転送
            tokenAddress = chain1Token;
            destinationBlockchainId = chain2BlockchainId;
            sourceChain = "Chain1";
            destChain = "Chain2";
        } else if (chainId == 5002) {
            // Chain2から Chain1へ転送
            tokenAddress = chain2Token;
            destinationBlockchainId = chain1BlockchainId;
            sourceChain = "Chain2";
            destChain = "Chain1";
        } else {
            revert("Unknown chain ID. Expected 5001 or 5002");
        }
        
        // 転送前の残高を表示
        uint256 balanceBefore = TeleporterERC20(tokenAddress).balanceOf(sender);
        console.log("=== Before Transfer ===");
        console.log("Source chain:", sourceChain);
        console.log("Sender balance:", balanceBefore / 1e18, "tokens");
        console.log("");

        // トランザクション開始
        vm.startBroadcast(deployerPrivateKey);

        // クロスチェーン転送を実行
        TeleporterERC20(tokenAddress).sendTokens(
            destinationBlockchainId,
            recipient,
            amount
        );

        vm.stopBroadcast();

        // 転送後の残高を表示
        uint256 balanceAfter = TeleporterERC20(tokenAddress).balanceOf(sender);
        
        console.log("=== Transfer Initiated ===");
        console.log("From:", sourceChain, "to", destChain);
        console.log("Amount:", amount / 1e18, "tokens");
        console.log("Recipient:", recipient);
        console.log("");
        console.log("=== After Transfer (Source Chain) ===");
        console.log("Sender balance:", balanceAfter / 1e18, "tokens");
        console.log("Tokens sent:", (balanceBefore - balanceAfter) / 1e18);
        console.log("");
        console.log("Note: Check destination chain balance after AWM Relayer delivers the message");
    }
}