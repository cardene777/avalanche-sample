// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/console.sol";
import {SampleERC20} from "../src/ictt/SampleERC20.sol";
import {ERC20TokenHomeUpgradeable} from "../src/ictt/TokenHome/ERC20TokenHomeUpgradeable.sol";
import {ERC20TokenRemoteUpgradeable} from "../src/ictt/TokenRemote/ERC20TokenRemoteUpgradeable.sol";
import {TokenRemoteSettings} from "../src/ictt/TokenRemote/interfaces/ITokenRemote.sol";
import {ICMInitializable} from "../src/utilities/ICMInitializable.sol";
import {Config} from "./Config.sol";

/**
 * @title DeployFujiHome
 * @notice Fuji C-Chain側のすべてのコントラクトをデプロイするスクリプト
 * @dev 使用方法:
 *      forge script script/DeployAll.s.sol:DeployFujiHome \
 *        --rpc-url $FUJI_RPC_URL \
 *        --private-key $PRIVATE_KEY \
 *        --broadcast \
 *        -vvvv
 *
 * @dev このスクリプトは以下を順番にデプロイします:
 *      1. Teleporter Messenger
 *      2. Teleporter Registry
 *      3. SampleERC20
 *      4. ERC20TokenHome
 */
contract DeployFujiHome is Script, Config {
    function run() external {
        console.log(unicode"=== Fuji Home側 完全デプロイ開始 ===");
        console.log("Deployer:", msg.sender);
        console.log("Chain ID:", block.chainid);
        console.log("");

        // Fuji testnetの既存Teleporter Registryを使用
        address teleporterRegistryAddress = vm.envOr(
            "FUJI_TELEPORTER_REGISTRY_ADDRESS",
            address(0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228)
        );

        console.log(unicode"既存のTeleporter Registryを使用:");
        console.log("   Teleporter Registry Address:", teleporterRegistryAddress);
        console.log("");

        vm.startBroadcast();

        // 1. SampleERC20のデプロイ
        console.log(unicode"1. SampleERC20 をデプロイ中...");
        string memory tokenName = vm.envOr("TOKEN_NAME", string("Sample Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("SMPL"));
        SampleERC20 sampleToken = new SampleERC20(tokenName, tokenSymbol);
        console.log("   Sample ERC20 Address:", address(sampleToken));
        console.log("   Token Name:", sampleToken.name());
        console.log("   Token Symbol:", sampleToken.symbol());
        console.log("   Token Decimals:", sampleToken.decimals());
        console.log("");

        // 2. ERC20TokenHomeUpgradeableのデプロイ
        console.log(unicode"2. ERC20TokenHomeUpgradeable をデプロイ中...");
        uint8 tokenDecimals = uint8(vm.envOr("TOKEN_DECIMALS", uint256(18)));

        // コントラクトのデプロイ（初期化なし）
        ERC20TokenHomeUpgradeable tokenHome = new ERC20TokenHomeUpgradeable(ICMInitializable.Allowed);
        console.log("   ERC20TokenHomeUpgradeable Address:", address(tokenHome));
        console.log("   Token Address:", address(sampleToken));
        console.log("");

        vm.stopBroadcast();

        // Blockchain IDを環境変数から取得
        bytes32 blockchainID = vm.envOr("FUJI_BLOCKCHAIN_ID", bytes32(0));

        // デプロイサマリー
        console.log("=================================================");
        console.log(unicode"=== Fuji Home側 デプロイ完了 ===");
        console.log("=================================================");
        console.log("");
        console.log(unicode"以下のアドレスを.envファイルに保存してください:");
        console.log("");
        console.log("TOKEN_HOME_BLOCKCHAIN_ID=", vm.toString(blockchainID));
        console.log("TOKEN_ADDRESS=", address(sampleToken));
        console.log("TOKEN_HOME_ADDRESS=", address(tokenHome));
        console.log("");
        console.log("=================================================");
        console.log(unicode"次のステップ:");
        console.log(unicode"1. 上記の設定を.envファイルに追加");
        console.log(unicode"2. make initialize-fuji を実行してTokenHomeを初期化");
        console.log(unicode"3. make deploy-dispatch を実行");
        console.log(unicode"4. make initialize-dispatch を実行");
        console.log(unicode"5. make register-remote でリモートチェーンを登録");
        console.log(unicode"6. make send でトークンを送信");
        console.log("=================================================");
    }
}

/**
 * @title DeployDispatchRemote
 * @notice Dispatch Testnet側のすべてのコントラクトをデプロイするスクリプト
 * @dev 使用方法:
 *      forge script script/DeployAll.s.sol:DeployDispatchRemote \
 *        --rpc-url $DISPATCH_RPC_URL \
 *        --private-key $PRIVATE_KEY \
 *        --broadcast \
 *        -vvvv
 *
 * @dev 必要な環境変数:
 *      - TOKEN_HOME_BLOCKCHAIN_ID: Fuji側のBlockchain ID
 *      - TOKEN_HOME_ADDRESS: Fuji側のERC20TokenHomeアドレス
 *      - TOKEN_HOME_DECIMALS: Fuji側のトークンdecimals
 *
 * @dev このスクリプトは以下を順番にデプロイします:
 *      1. Teleporter Messenger
 *      2. Teleporter Registry
 *      3. ERC20TokenRemote
 */
contract DeployDispatchRemote is Script, Config {
    function run() external {
        // 環境変数から必要なパラメータを取得
        bytes32 tokenHomeBlockchainID = vm.envBytes32("TOKEN_HOME_BLOCKCHAIN_ID");
        address tokenHomeAddress = vm.envAddress("TOKEN_HOME_ADDRESS");
        uint8 tokenHomeDecimals = uint8(vm.envOr("TOKEN_HOME_DECIMALS", uint256(18)));

        // Dispatch testnetの既存Teleporter Registryを使用
        address teleporterRegistryAddress = vm.envOr(
            "DISPATCH_TELEPORTER_REGISTRY_ADDRESS",
            address(0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228)
        );

        console.log(unicode"=== Dispatch Remote側 完全デプロイ開始 ===");
        console.log("Deployer:", msg.sender);
        console.log("Chain ID:", block.chainid);
        console.log("Token Home Blockchain ID:", vm.toString(tokenHomeBlockchainID));
        console.log("Token Home Address:", tokenHomeAddress);
        console.log("Token Home Decimals:", tokenHomeDecimals);
        console.log("");

        console.log(unicode"既存のTeleporter Registryを使用:");
        console.log("   Teleporter Registry Address:", teleporterRegistryAddress);
        console.log("");

        vm.startBroadcast();

        // 1. ERC20TokenRemoteUpgradeableのデプロイ
        console.log(unicode"1. ERC20TokenRemoteUpgradeable をデプロイ中...");

        // コントラクトのデプロイ（初期化なし）
        ERC20TokenRemoteUpgradeable tokenRemote = new ERC20TokenRemoteUpgradeable(ICMInitializable.Allowed);
        console.log("   ERC20TokenRemoteUpgradeable Address:", address(tokenRemote));
        console.log("");

        vm.stopBroadcast();

        // Blockchain IDを環境変数から取得
        bytes32 dispatchBlockchainID = vm.envOr("DISPATCH_BLOCKCHAIN_ID", bytes32(0));

        // デプロイサマリー
        console.log("=================================================");
        console.log(unicode"=== Dispatch Remote側 デプロイ完了 ===");
        console.log("=================================================");
        console.log("");
        console.log(unicode"以下のアドレスを.envファイルに保存してください:");
        console.log("");
        console.log("DISPATCH_BLOCKCHAIN_ID=", vm.toString(dispatchBlockchainID));
        console.log("REMOTE_TOKEN_TRANSFERRER_ADDRESS=", address(tokenRemote));
        console.log("");
        console.log("=================================================");
        console.log(unicode"次のステップ:");
        console.log(unicode"1. 上記の設定を.envファイルに追加");
        console.log(unicode"2. make initialize-dispatch を実行してTokenRemoteを初期化");
        console.log(unicode"3. make register-remote を実行してリモートチェーンを登録");
        console.log(unicode"4. make mint でトークンをミント");
        console.log(unicode"5. make send でトークンを送信");
        console.log("=================================================");
    }
}
