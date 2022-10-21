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

    function testDeployUsingHuffDeployer() public {
        bytes memory args = abi.encode(address(token));
        address pod = huffConfig.with_args(args).deploy("Pod");

        assertEq(token.allowance(pod, address(huffConfig)), type(uint256).max);
    }

    function testDeployUsingPureSolidity() public {
        address pod;
        bytes memory bytecode = abi.encodePacked(_podCreationCode(), abi.encode(address(token)));

        assembly {
            pod := create2(0, add(bytecode, 0x20), mload(bytecode), 0)

            if iszero(pod) {
                revert(0, 0)
            }
        }

        assertEq(token.allowance(pod, address(this)), type(uint256).max);
    }

    function _podCreationCode() private returns (bytes memory) {
        string[] memory cmds = new string[](3);
        cmds[0] = "huffc";
        cmds[1] = "src/Pod.huff";
        cmds[2] = "-b";
        return vm.ffi(cmds);
    }
}
