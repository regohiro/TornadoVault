// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { TornadoVault, ITornadoVault } from "../src/TornadoVault.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

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
    ) public {
        vm.assume(tokenAddr != address(0));
        vm.assume(lowerBound < upperBound);

        vault.addTokenRule(tokenAddr, 1e18, 3e18);

        vm.expectEmit(true, false, false, true);
        emit UpdateTokenRule(tokenAddr, disabled, lowerBound, upperBound);
        vault.updateTokenRule(tokenAddr, disabled, lowerBound, upperBound);
        assertEq(
            abi.encode(vault.tokenRule(tokenAddr)),
            abi.encode(TokenRule(tokenAddr, disabled, lowerBound, upperBound))
        );
    }

    function testSetLimit(uint256 limit) public {
        vm.expectEmit(false, false, false, true);
        emit SetLimit(limit);
        vault.setLimit(limit);
        assertEq(vault.limit(), limit);
    }

    function testCheckUpKeepNoTokenRule() public {
        vm.prank(address(0), address(0));
        (bool perform, ) = vault.checkUpKeep("0x");
        assertFalse(perform);
    }

    function testCheckUpKeepNoBalance() public {
        vault.addTokenRule(address(token), 1e18, 3e18);
        vm.prank(address(0), address(0));
        (bool perform, ) = vault.checkUpKeep("0x");
        assertFalse(perform);
    }

    function testCheckUpKeepOverUpperBound() public {
        vault.addTokenRule(address(token), 1e18, 3e18);

        token.mint(address(vault), 5e18);

        vm.prank(address(0), address(0));
        (bool perform, bytes memory performData) = vault.checkUpKeep("0x");

        ActionToken[] memory actionTokens = new ActionToken[](1);
        actionTokens[0] = ActionToken(address(token), Action.REMOVE, 1e18);
        assertTrue(perform);
        assertEq(performData, abi.encode(actionTokens));
    }

    function testPerformUpKeepOverUpperBound(
        uint256 amount,
        uint256 lowerBound,
        uint256 upperBound
    ) public {
        vm.assume(amount > upperBound);
        vm.assume(lowerBound < upperBound);

        vault.addTokenRule(address(token), lowerBound, upperBound);
        token.mint(address(vault), amount);

        vm.prank(address(0), address(0));
        (bool perform, bytes memory performData) = vault.checkUpKeep("0x");

        vm.prank(keeper, keeper);
        vault.performUpkeep(performData);

        // More tests...
        assertTrue(perform);
    }
}
