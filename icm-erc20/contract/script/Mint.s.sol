// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TeleporterERC20} from "../src/TeleporterERC20.sol";

/**
 * トークンミントスクリプト
 * Chain1でのみ実行することを想定
 */
contract MintScript is Script {
    function run() external {
        // 環境変数から設定を読み込む
        address tokenAddress = vm.envAddress("CHAIN1_TOKEN_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // デフォルト値
        address recipient = 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC;
        uint256 amount = 1000 ether;

        // トランザクション開始
        vm.startBroadcast(deployerPrivateKey);

        // トークンをミント
        TeleporterERC20(tokenAddress).mint(recipient, amount);

        vm.stopBroadcast();

        console.log("Minted tokens successfully");
        console.log("Token:", tokenAddress);
        console.log("Recipient:", recipient);
        console.log("Amount:", amount);
    }
}