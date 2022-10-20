// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { HuffConfig } from "foundry-huff/HuffConfig.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract PodTest is Test {
    HuffConfig huffConfig;
    MockERC20 token;

    function setUp() public {
        token = new MockERC20("Wrapped Ether", "wETH", 18);
        huffConfig = new HuffConfig();

        vm.label(address(token), "token");
        vm.label(address(huffConfig), "config");
    }

    function testDeployPod() public {
        bytes memory args = abi.encode(address(token));
        address pod = huffConfig.with_args(args).deploy("Pod");

        assertEq(token.allowance(pod, address(huffConfig)), type(uint256).max);
    }
}
