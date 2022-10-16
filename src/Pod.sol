// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";

contract Pod {
    address public immutable vault;
    error OnlyVault();

    constructor(address vault_) {
        vault = vault_;
    }

    function pull(address token) external {
        if (msg.sender != vault) {
            revert OnlyVault();
        }
        ERC20(token).transfer(vault, ERC20(token).balanceOf(address(this)));
    }
}
