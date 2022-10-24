// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Config {
    struct NetworkConfig {
        uint256 limit;
        address keeper;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 => NetworkConfig) private _networkConfigs;

    constructor() {
        _networkConfigs[1] = NetworkConfig({
            limit: 10,
            keeper: address(0x02777053d6764996e594c3E88AF1D58D5363a2e6)
        });
        _networkConfigs[5] = NetworkConfig({
            limit: 10,
            keeper: address(0x02777053d6764996e594c3E88AF1D58D5363a2e6)
        });

        activeNetworkConfig = _networkConfigs[block.chainid];
    }
}
