// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/console.sol";
import {SampleERC20} from "../src/ictt/SampleERC20.sol";
import {ERC20TokenHomeUpgradeable} from "../src/ictt/TokenHome/ERC20TokenHomeUpgradeable.sol";
import {ERC20TokenRemoteUpgradeable} from "../src/ictt/TokenRemote/ERC20TokenRemoteUpgradeable.sol";
import {ICMInitializable} from "../src/utilities/ICMInitializable.sol";

/**
 * @title DeployFujiHome
 * @notice Fuji C-Chain側のコントラクトをデプロイするスクリプト
 * @dev 使用方法:
 *      forge script script/Deploy.s.sol:DeployFujiHome --rpc-url fuji --broadcast
 */
contract DeployFujiHome is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        console.log(unicode"=== Fuji Home側デプロイ開始 ===");
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
        console.log("TOKEN_HOME_ADDRESS=", address(tokenHome));
        console.log("=================================================");
    }
}

/**
 * @title DeployDispatchRemote
 * @notice Dispatch Testnet側のコントラクトをデプロイするスクリプト
 * @dev 使用方法:
 *      forge script script/Deploy.s.sol:DeployDispatchRemote --rpc-url dispatch --broadcast
 */
contract DeployDispatchRemote is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        console.log(unicode"=== Dispatch Remote側デプロイ開始 ===");
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
        console.log("REMOTE_TOKEN_TRANSFERRER_ADDRESS=", address(tokenRemote));
        console.log("=================================================");
    }
}
