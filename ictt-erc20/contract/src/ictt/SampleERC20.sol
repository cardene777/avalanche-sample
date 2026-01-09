// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * サンプルERC20トークン
 * 誰でもmintできるシンプルなERC20トークン実装
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SampleERC20 is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}

    /**
     * 誰でも自由にトークンをmintできる関数
     * @param to mint先のアドレス
     * @param amount mint量
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
