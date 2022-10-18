// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";

contract Pod {
    constructor(address vault, address token) {
        ERC20(token).approve(vault, type(uint256).max);
    }
}
