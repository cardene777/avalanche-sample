// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/TeleporterERC20.sol";

/**
 * クロスチェーン転送を実行するスクリプト
 * 使用方法:
 * - TOKEN_ADDRESS: 送信元チェーンのトークンアドレス
 * - DESTINATION_CHAIN_ID: 送信先チェーンのBlockchain ID
 * - TRANSFER_TO: 受信者アドレス（デフォルト: DEFAULT_RECIPIENT）
 * - TRANSFER_AMOUNT: 転送量（デフォルト: 100 * 10^18）
 */
contract TransferToken is Script {
    function run() external {
        // 環境変数から設定を取得
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        bytes32 destinationChainId = vm.envBytes32("DESTINATION_CHAIN_ID");
        address transferTo = vm.envOr("TRANSFER_TO", vm.envAddress("DEFAULT_RECIPIENT"));
        uint256 transferAmount = vm.envOr("TRANSFER_AMOUNT", uint256(100 * 10**18));
        
        // 秘密鍵からアドレスを導出
        address sender = vm.addr(deployerPrivateKey);
        
        TeleporterERC20 token = TeleporterERC20(tokenAddress);
        
        console.log("Initiating cross-chain transfer...");
        console.log("From token:", tokenAddress);
        console.log("From address:", sender);
        console.log("To chain ID:", vm.toString(destinationChainId));
        console.log("Recipient:", transferTo);
        console.log("Amount:", transferAmount);
        
        // 送信者の残高確認
        uint256 balanceBefore = token.balanceOf(sender);
        console.log("Sender balance:", balanceBefore);
        require(balanceBefore >= transferAmount, "Insufficient balance");
        
        // 転送実行
        vm.startBroadcast(deployerPrivateKey);
        
        token.sendTokens(destinationChainId, transferTo, transferAmount);
        
        vm.stopBroadcast();
        
        // 結果を表示
        uint256 balanceAfter = token.balanceOf(sender);
        console.log("Transfer initiated!");
        console.log("Balance before:", balanceBefore);
        console.log("Balance after:", balanceAfter);
        console.log("Tokens will arrive on destination chain in ~10-30 seconds");
    }
}