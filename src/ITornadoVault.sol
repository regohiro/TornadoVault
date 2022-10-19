// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    error OnlyKeeper();
    error TokenAlreadyAdded();
    error TokenNotAdded();
    error ZeroAddress();
    error InvalidBounds();
}

interface ITornadoVault {
    struct TokenRule {
        address token;
        bool disabled;
        uint256 lowerBound;
        uint256 upperBound;
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

    event AddTokenRule(address indexed token, uint256 lowerBound, uint256 upperBound);
    event UpdateTokenRule(
        address indexed token,
        bool disabled,
        uint256 lowerBound,
        uint256 upperBound
    );
    event SetLimit(uint256 limit);

    enum Action {
        ADD,
        REMOVE
    }
}
