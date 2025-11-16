// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {TeleporterERC20} from "../src/TeleporterERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DebugTokenSendScript
 * @dev トークン送信のデバッグ用スクリプト
 */
contract DebugTokenSendScript is Script {
    function run() external {
        // 環境変数の読み取り
        address tokenAddress = vm.envAddress("LOCAL_L1_TOKEN_ADDRESS");
        bytes32 destinationChainID = vm.envBytes32("LOCAL_L2_BLOCKCHAIN_ID_HEX");
        address destinationAddress = vm.envAddress("LOCAL_L2_TOKEN_ADDRESS");
        address sender = vm.addr(vm.envUint("DEPLOY_PK"));
        
        console2.log("=== Debug Token Send ===");
        console2.log("Token Address:", tokenAddress);
        console2.log("Destination Chain ID:");
        console2.logBytes32(destinationChainID);
        console2.log("Destination Address:", destinationAddress);
        console2.log("Sender:", sender);
        
        vm.startBroadcast(vm.envUint("DEPLOY_PK"));
        
        TeleporterERC20 token = TeleporterERC20(tokenAddress);
        
        // 残高確認
        uint256 balance = token.balanceOf(sender);
        console2.log("Sender balance:", balance);
        
        // Teleporter Messengerアドレス確認
        address teleporter = address(token.teleporterMessenger());
        console2.log("Teleporter Messenger:", teleporter);
        
        // 送信量
        uint256 amount = 1 ether; // 1トークン
        console2.log("Amount to send:", amount);
        
        // 送信前のチェック
        require(balance >= amount, "Insufficient balance");
        require(teleporter != address(0), "Teleporter not set");
        require(destinationAddress != address(0), "Destination not set");
        
        // トークン送信実行
        try token.sendTokens(destinationChainID, destinationAddress, sender, amount) {
            console2.log("Token send successful!");
        } catch Error(string memory reason) {
            console2.log("Error:", reason);
        } catch (bytes memory data) {
            console2.log("Low-level error:");
            console2.logBytes(data);
        }
        
        vm.stopBroadcast();
    }
}