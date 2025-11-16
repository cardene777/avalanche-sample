// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TeleporterERC20} from "../src/TeleporterERC20.sol";

/**
 * シンプルな転送テスト
 */
contract SimpleTransferScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = vm.envAddress("CHAIN1_TOKEN_ADDRESS");
        bytes32 destinationChainId = vm.envBytes32("CHAIN2_BLOCKCHAIN_ID");
        
        TeleporterERC20 token = TeleporterERC20(tokenAddress);
        
        // 現在の残高を確認
        address account = 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC;
        uint256 balance = token.balanceOf(account);
        console.log("Current balance:", balance);
        
        if (balance == 0) {
            console.log("No balance to transfer");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 少額を転送
        uint256 amount = 10 * 10**18; // 10 tokens
        console.log("Attempting to transfer:", amount);
        
        try token.sendTokens(destinationChainId, account, amount) {
            console.log("Transfer initiated successfully");
        } catch Error(string memory reason) {
            console.log("Transfer failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Transfer failed with low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
    }
}