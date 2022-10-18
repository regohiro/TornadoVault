// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { TornadoVault } from "../src/TornadoVault.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

enum Action {
    ADD,
    REMOVE
}

contract TornadoVaultTest is Test {
    MockERC20 token;
    TornadoVault vault;

    // function setUp() public {
    //     token = new MockERC20("Bitcoin", "BTC", 18);
    //     vault = new TornadoVault();
    //     vm.label(address(token), "token");
    //     vm.label(address(vault), "vault");

    //     vault.setToken(address(token));
    //     vault.setBound(1_000_000e18, 3_000_000e18);
    // }

    // function testCheckUpKeepNoBalance() public {
    //     (bool perform, ) = vault.checkUpKeep("0x");
    //     assertFalse(perform);
    // }

    // function testCheckUpKeepOverMax() public {
    //     token.mint(address(vault), 5_000_000e18);
    //     (bool perform, bytes memory performData) = vault.checkUpKeep("0x");
    //     assertTrue(perform);
    //     assertEq(performData, abi.encode(Action.REMOVE));
    // }

    // function testPerformUpKeepOverMax() public {
    //     token.mint(address(vault), 5_000_000e18);
    //     (bool perform, bytes memory performData) = vault.checkUpKeep("0x");
    //     vault.performUpkeep(performData);

    //     address pod = vault.pods(0);
    //     assertEq(token.balanceOf(pod), 1_000_000e18);
    // }
}
