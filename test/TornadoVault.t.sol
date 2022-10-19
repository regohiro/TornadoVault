// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { TornadoVault, ITornadoVault } from "../src/TornadoVault.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

enum Action {
    ADD,
    REMOVE
}

contract TornadoVaultTest is Test, ITornadoVault {
    MockERC20 token;
    TornadoVault vault;
    address public immutable keeper = address(0x123);

    function setUp() public {
        token = new MockERC20("Wrapped Ether", "wETH", 18);
        vault = new TornadoVault(5, keeper);

        vm.label(address(token), "token");
        vm.label(address(vault), "vault");
    }

    function testAddTokenRule(
        address tokenAddr,
        uint256 lowerBound,
        uint256 upperBound
    ) public {
        vm.assume(tokenAddr != address(0));
        vm.assume(lowerBound < upperBound);

        vm.expectEmit(true, false, false, true);
        emit AddTokenRule(tokenAddr, lowerBound, upperBound);
        vault.addTokenRule(tokenAddr, lowerBound, upperBound);
        assertEq(
            abi.encode(vault.tokenRule(tokenAddr)),
            abi.encode(TokenRule(tokenAddr, false, lowerBound, upperBound))
        );
    }

    function testUpdateTokenRule(
        address tokenAddr,
        bool disabled,
        uint256 lowerBound,
        uint256 upperBound
    ) public {}

    function testSetLimit(uint256 limit) public {
        vm.expectEmit(false, false, false, true);
        emit SetLimit(limit);
        vault.setLimit(limit);
        assertEq(vault.limit(), limit);
    }

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
