// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../test/mocks/MockERC20.sol";
import "forge-std/Script.sol";

contract DeployMockToken is Script {
    function run() public {
        vm.startBroadcast();

        new MockERC20("Dogecoin", "DOGE", 18);

        vm.stopBroadcast();
    }
}
