// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * SimpleNFTコントラクトのデプロイスクリプト
 **/

import {Script, console} from "forge-std/Script.sol";
import {SimpleNFT} from "../src/SimpleNFT.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        // 環境変数からプライベートキーを取得
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // デプロイ開始
        vm.startBroadcast(deployerPrivateKey);
        
        // NFTコントラクトのパラメータ
        string memory name = "Simple NFT";
        string memory symbol = "SNFT";
        string memory baseURI = "https://api.example.com/metadata/";
        
        // コントラクトをデプロイ
        SimpleNFT nft = new SimpleNFT(name, symbol, baseURI);
        
        console.log("SimpleNFT deployed at:", address(nft));
        console.log("Name:", name);
        console.log("Symbol:", symbol);
        console.log("Base URI:", baseURI);
        
        vm.stopBroadcast();
    }
}