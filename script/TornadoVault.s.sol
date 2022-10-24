// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Config.sol";
import "../src/TornadoVault.sol";
import "forge-std/Script.sol";

contract DeployTornadoVault is Script {
    function run() public {
        Config config = new Config();

        (uint256 limit, address keeper) = config.activeNetworkConfig();

        vm.startBroadcast();

        new TornadoVault(limit, keeper);

        vm.stopBroadcast();
    }
}
