// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/TeleporterERC20.sol";

/**
 * トークンをmintするスクリプト
 * 使用方法:
 * - MINT_TO: mint先のアドレス（デフォルト: DEFAULT_RECIPIENT）
 * - MINT_AMOUNT: mint量（デフォルト: 1000 * 10^18）
 */
contract MintToken is Script {
    function run() external {
        // 環境変数から設定を取得
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address mintTo = vm.envOr("MINT_TO", vm.envAddress("DEFAULT_RECIPIENT"));
        uint256 mintAmount = vm.envOr("MINT_AMOUNT", uint256(1000 * 10**18));
        
        // mint実行
        vm.startBroadcast(deployerPrivateKey);
        
        TeleporterERC20 token = TeleporterERC20(tokenAddress);
        
        console.log("Minting tokens...");
        console.log("Token address:", tokenAddress);
        console.log("Recipient:", mintTo);
        console.log("Amount:", mintAmount);
        
        token.mint(mintTo, mintAmount);
        
        vm.stopBroadcast();
        
        // 結果を表示
        uint256 balance = token.balanceOf(mintTo);
        console.log("New balance:", balance);
        console.log("Mint successful!");
    }
}