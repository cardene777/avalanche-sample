// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/console.sol";
import {SampleERC20} from "../src/ictt/SampleERC20.sol";

/**
 * @title MintToken
 * @notice トークンをミントするスクリプト
 * @dev 使用方法:
 *      forge script script/Token.s.sol:MintToken --rpc-url fuji --broadcast
 */
contract MintToken is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        // 環境変数から設定を取得
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        uint256 mintAmount = vm.envOr("MINT_AMOUNT", uint256(100 ether)); // デフォルト100トークン
        address recipient = vm.envOr("MINT_RECIPIENT", deployer);

        console.log(unicode"=== トークンミント ===");
        console.log("Token:", tokenAddress);
        console.log("Recipient:", recipient);
        console.log("Amount:", mintAmount);
        console.log("");

        vm.startBroadcast(privateKey);

        SampleERC20 token = SampleERC20(tokenAddress);
        token.mint(recipient, mintAmount);

        vm.stopBroadcast();

        console.log(unicode"=== ミント完了 ===");
    }
}
