// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/SimpleERC20.sol";

contract DeployC is Script {
    function run() external {
        vm.startBroadcast();
        
        // Deploy ERC20 on C-Chain
        SimpleERC20 token = new SimpleERC20(
            "Teleporter TEST",
            "TTEST",
            18
        );
        
        // Mint initial tokens to deployer
        token.mint(msg.sender, 1000000 * 10**18);
        
        console.log("Token deployed at:", address(token));
        console.log("Minted 1000000 tokens to:", msg.sender);
        
        vm.stopBroadcast();
    }
}