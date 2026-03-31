// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/console.sol";
import {SampleERC20} from "../src/ictt/SampleERC20.sol";
import {ERC20TokenHomeUpgradeable} from "../src/ictt/TokenHome/ERC20TokenHomeUpgradeable.sol";
import {ERC20TokenRemoteUpgradeable} from "../src/ictt/TokenRemote/ERC20TokenRemoteUpgradeable.sol";
import {ICMInitializable} from "../src/utilities/ICMInitializable.sol";

/**
 * @title DeployHome
 * @notice Home側のコントラクト（ERC20 + TokenHome）をデプロイするスクリプト
 * @dev 使用方法:
 *      forge script script/Deploy.s.sol:DeployHome --rpc-url home --broadcast
 */
contract DeployHome is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        console.log(unicode"=== Home側デプロイ開始 ===");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(privateKey);

        // 1. SampleERC20のデプロイ
        console.log(unicode"1. SampleERC20 をデプロイ中...");
        string memory tokenName = vm.envOr("TOKEN_NAME", string("Sample Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("SMPL"));
        SampleERC20 sampleToken = new SampleERC20(tokenName, tokenSymbol);
        console.log("   Address:", address(sampleToken));
        console.log("");

        // 2. ERC20TokenHomeUpgradeableのデプロイ
        console.log(unicode"2. ERC20TokenHomeUpgradeable をデプロイ中...");
        ERC20TokenHomeUpgradeable tokenHome = new ERC20TokenHomeUpgradeable(ICMInitializable.Allowed);
        console.log("   Address:", address(tokenHome));
        console.log("");

        vm.stopBroadcast();

        // デプロイサマリー
        console.log("=================================================");
        console.log(unicode"デプロイ完了！以下を.envに追加してください:");
        console.log("");
        console.log("TOKEN_ADDRESS=", address(sampleToken));
        console.log("HOME_ADDRESS=", address(tokenHome));
        console.log("=================================================");
    }
}

/**
 * @title DeployERC20
 * @notice ERC20トークンのみをデプロイするスクリプト
 * @dev 使用方法:
 *      forge script script/Deploy.s.sol:DeployERC20 --rpc-url home --broadcast
 */
contract DeployERC20 is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        console.log(unicode"=== ERC20デプロイ開始 ===");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(privateKey);

        string memory tokenName = vm.envOr("TOKEN_NAME", string("Sample Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("SMPL"));
        SampleERC20 sampleToken = new SampleERC20(tokenName, tokenSymbol);
        console.log("   Address:", address(sampleToken));
        console.log("");

        vm.stopBroadcast();

        console.log("=================================================");
        console.log(unicode"デプロイ完了！以下を.envに追加してください:");
        console.log("");
        console.log("TOKEN_ADDRESS=", address(sampleToken));
        console.log("=================================================");
    }
}

/**
 * @title DeployERC20AndMint
 * @notice ERC20トークンをデプロイしてMintまで行うスクリプト
 * @dev 使用方法:
 *      forge script script/Deploy.s.sol:DeployERC20AndMint --rpc-url home --broadcast
 */
contract DeployERC20AndMint is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        uint256 mintAmount = vm.envOr("MINT_AMOUNT", uint256(100 * 10 ** 18));

        console.log(unicode"=== ERC20デプロイ & Mint開始 ===");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(privateKey);

        // 1. ERC20デプロイ
        console.log(unicode"1. SampleERC20 をデプロイ中...");
        string memory tokenName = vm.envOr("TOKEN_NAME", string("Sample Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("SMPL"));
        SampleERC20 sampleToken = new SampleERC20(tokenName, tokenSymbol);
        console.log("   Address:", address(sampleToken));
        console.log("");

        // 2. Mint
        console.log(unicode"2. トークンをMint中...");
        sampleToken.mint(deployer, mintAmount);
        console.log("   Amount:", mintAmount);
        console.log("");

        vm.stopBroadcast();

        console.log("=================================================");
        console.log(unicode"デプロイ & Mint完了！");
        console.log("");
        console.log("TOKEN_ADDRESS=", address(sampleToken));
        console.log("MINT_AMOUNT=", mintAmount);
        console.log("=================================================");
    }
}

/**
 * @title DeployRemote
 * @notice Remote側のコントラクト（TokenRemote）をデプロイするスクリプト
 * @dev 使用方法:
 *      forge script script/Deploy.s.sol:DeployRemote --rpc-url remote --broadcast
 */
contract DeployRemote is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        console.log(unicode"=== Remote側デプロイ開始 ===");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(privateKey);

        // ERC20TokenRemoteUpgradeableのデプロイ
        console.log(unicode"ERC20TokenRemoteUpgradeable をデプロイ中...");
        ERC20TokenRemoteUpgradeable tokenRemote = new ERC20TokenRemoteUpgradeable(ICMInitializable.Allowed);
        console.log("   Address:", address(tokenRemote));
        console.log("");

        vm.stopBroadcast();

        // デプロイサマリー
        console.log("=================================================");
        console.log(unicode"デプロイ完了！以下を.envに追加してください:");
        console.log("");
        console.log("REMOTE_ADDRESS=", address(tokenRemote));
        console.log("=================================================");
    }
}
