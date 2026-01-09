// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: LicenseRef-Ecosystem

pragma solidity 0.8.30;

import {Test} from "@forge-std/Test.sol";
import {SampleERC20} from "../src/ictt/SampleERC20.sol";

/**
 * SampleERC20のdecimals関数のテスト
 */
contract SampleERC20DecimalsTest is Test {
    uint8 public constant DEFAULT_DECIMALS = 18;
    SampleERC20 public sampleERC20;

    /**
     * @notice テスト環境のセットアップ
     * @dev SampleERC20トークンをデプロイする
     */
    function setUp() public virtual {
        sampleERC20 = new SampleERC20("Sample Token", "SMPL");
    }

    /**
     * @notice decimals関数がデフォルト値18を返すことを確認するテスト
     * @dev ERC20のdecimals()がOPENZeppelinのデフォルト値18を返すことを検証
     */
    function testDecimals() public view {
        assertEq(sampleERC20.decimals(), DEFAULT_DECIMALS);
    }
}
