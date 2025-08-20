// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/TeleporterERC20.sol";

/**
 * 残高確認スクリプト
 * 環境変数:
 * - TOKEN_ADDRESS: トークンアドレス
 * - CHECK_ADDRESS: 残高を確認するアドレス（オプション）
 * - CHAIN_NAME: チェーン名（オプション）
 */
contract CheckBalance is Script {
    function run() external view {
        // 環境変数から設定を読み込む
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address checkAddress = vm.envOr("CHECK_ADDRESS", vm.envAddress("DEFAULT_RECIPIENT"));
        string memory chainName = vm.envOr("CHAIN_NAME", string("Chain"));
        
        // トークンコントラクトから残高を取得
        TeleporterERC20 token = TeleporterERC20(tokenAddress);
        uint256 balance = token.balanceOf(checkAddress);
        
        // 結果を表示
        console.log("=== %s Balance ===", chainName);
        console.log("Address:", checkAddress);
        console.log("Raw:", balance);
        
        // トークン単位で表示（18 decimals）
        if (balance == 0) {
            console.log("Formatted: 0 tokens");
        } else {
            uint256 wholePart = balance / 1e18;
            uint256 decimalPart = (balance % 1e18) / 1e15; // 3桁まで表示
            
            if (decimalPart == 0) {
                console.log("Formatted:", wholePart, "tokens");
            } else {
                console.log(string.concat(
                    "Formatted: ",
                    vm.toString(wholePart),
                    ".",
                    _padZeros(decimalPart, 3),
                    " tokens"
                ));
            }
        }
    }
    
    function _padZeros(uint256 value, uint256 digits) internal pure returns (string memory) {
        string memory str = vm.toString(value);
        bytes memory strBytes = bytes(str);
        
        if (strBytes.length >= digits) {
            return str;
        }
        
        // 先頭にゼロを追加
        bytes memory result = new bytes(digits);
        uint256 padding = digits - strBytes.length;
        
        for (uint256 i = 0; i < padding; i++) {
            result[i] = "0";
        }
        
        for (uint256 i = 0; i < strBytes.length; i++) {
            result[padding + i] = strBytes[i];
        }
        
        return string(result);
    }
}