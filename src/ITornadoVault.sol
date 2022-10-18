// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    error OnlyKeeper();
    error TokenAlreadyAdded();
    error TokenNotAdded();
}

interface ITornadoVault {
    struct TokenRule {
        address token;
        bool disabled;
        uint256 min;
        uint256 max;
    }

    struct ActionToken {
        address token;
        Action action;
        uint256 amount;
    }

    struct PodNonce {
        uint128 right;
        uint128 left;
    }

    event AddTokenRule(address token, uint256 min, uint256 max);
    event UpdateTokenRule(address token, bool disabled, uint256 min, uint256 max);
    event SetLimit(uint256 limit);

    enum Action {
        ADD,
        REMOVE
    }
}
