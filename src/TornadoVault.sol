// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Pod } from "./Pod.sol";

contract TornadoVault {
    address public token;
    uint256 public min;
    uint256 public max;
    address[] public pods;

    enum Action {
        ADD,
        REMOVE
    }

    function setToken(address token_) external {
        token = token_;
    }

    function setBound(uint256 min_, uint256 max_) external {
        min = min_;
        max = max_;
    }

    function checkUpKeep(bytes calldata) external view returns (bool, bytes memory) {
        uint256 balance = ERC20(token).balanceOf(address(this));
        if (balance > max) {
            return (true, abi.encode(Action.REMOVE));
        } else if (balance < min && pods.length > 0) {
            return (true, abi.encode(Action.ADD));
        } else {
            return (false, "0x");
        }
    }

    function performUpkeep(bytes calldata performData) external {
        Action action = abi.decode(performData, (Action));
        if (action == Action.REMOVE) {
            address pod = address(new Pod(address(this)));
            pods.push(pod);
            ERC20(token).transfer(pod, (max - min) / 2);
        } else if (action == Action.ADD) {
            address pod = pods[pods.length - 1];
            pods.pop();
            Pod(pod).pull(token);
        }
    }
}
