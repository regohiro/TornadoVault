// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ITornadoVault, Errors } from "./ITornadoVault.sol";
import { AutomationBase } from "./utils/AutomationBase.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

contract TornadoVault is ITornadoVault, AutomationBase {
    // Multi-transaction limit
    uint256 public limit;
    // Chainlink keeper address
    address public immutable keeper;

    // List of token rules
    TokenRule[] private _tokenRules;
    // Index of token address in _tokenRules[]
    mapping(address => uint256) private _tokenIndex;
    // Left, right nonce of token pods
    mapping(address => PodNonce) private _podNonce;

    constructor(uint256 limit_, address keeper_) {
        limit = limit_;
        keeper = keeper_;

        assembly {
            sstore(_tokenRules.slot, 1)
        }
    }

    function tokenRule(address token) external view returns (TokenRule memory) {
        return _tokenRules[_getTokenIndex(token)];
    }

    function nonceOf(address token) external view returns (uint128, uint128) {
        return (_podNonce[token].left, _podNonce[token].right);
    }

    function addTokenRule(
        address token,
        uint256 lowerBound,
        uint256 upperBound
    ) external {
        if (token == address(0)) revert Errors.ZeroAddress();
        if (lowerBound > upperBound) revert Errors.InvalidBounds();
        if (_tokenIndex[token] != 0) revert Errors.TokenAlreadyAdded();

        _tokenIndex[token] = _tokenRules.length;
        _tokenRules.push(TokenRule(token, false, lowerBound, upperBound));

        emit AddTokenRule(token, lowerBound, upperBound);
    }

    function updateTokenRule(
        address token,
        bool disabled,
        uint256 lowerBound,
        uint256 upperBound
    ) external {
        if (lowerBound >= upperBound) revert Errors.InvalidBounds();

        _tokenRules[_getTokenIndex(token)] = TokenRule(token, disabled, lowerBound, upperBound);

        emit UpdateTokenRule(token, disabled, lowerBound, upperBound);
    }

    function setLimit(uint256 limit_) external {
        limit = limit_;

        emit SetLimit(limit);
    }

    function checkUpKeep(bytes calldata) external view cannotExecute returns (bool, bytes memory) {
        uint256 len = _tokenRules.length;
        uint256 num = 0;

        ActionToken[] memory actionTokens = new ActionToken[](len < limit ? len : limit);

        for (uint256 i = 1; i < len && num < limit; i++) {
            if (_tokenRules[i].disabled) {
                continue;
            }

            address token = _tokenRules[i].token;
            uint256 balance = ERC20(token).balanceOf(address(this));
            if (balance > _tokenRules[i].upperBound) {
                actionTokens[num++] = ActionToken(
                    token,
                    Action.REMOVE,
                    (_tokenRules[i].upperBound - _tokenRules[i].lowerBound) / 2
                );
            } else if (
                balance < _tokenRules[i].lowerBound &&
                _podNonce[token].left < _podNonce[token].right
            ) {
                bytes32 salt = keccak256(abi.encodePacked(token, _podNonce[token].left));
                address pod = _computePodAddress(salt);
                actionTokens[num++] = ActionToken(token, Action.ADD, ERC20(token).balanceOf(pod));
            }
        }

        if (num == 0) {
            return (false, "0x");
        }

        assembly {
            mstore(actionTokens, num)
        }
        return (true, abi.encode(actionTokens));
    }

    function performUpkeep(bytes calldata performData) external {
        ActionToken[] memory actionTokens = abi.decode(performData, (ActionToken[]));

        for (uint256 i = 0; i < actionTokens.length; i++) {
            address token = actionTokens[i].token;
            if (actionTokens[i].action == Action.REMOVE) {
                bytes32 salt = keccak256(abi.encodePacked(token, _podNonce[token].right++));
                bytes memory bytecode = abi.encodePacked(
                    _podCreationCode(),
                    abi.encode(address(token))
                );
                address pod;

                assembly {
                    pod := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
                    if iszero(pod) {
                        revert(0, 0)
                    }
                }

                ERC20(token).transfer(pod, actionTokens[i].amount);
            } else if (actionTokens[i].action == Action.ADD) {
                bytes32 salt = keccak256(abi.encodePacked(token, _podNonce[token].left++));
                address pod = _computePodAddress(salt);

                ERC20(token).transferFrom(pod, address(this), actionTokens[i].amount);
            }
        }
    }

    function _getTokenIndex(address token) private view returns (uint256 index) {
        if ((index = _tokenIndex[token]) == 0) revert Errors.TokenNotAdded();
    }

    function _podCreationCode() private pure returns (bytes memory) {
        return
            hex"63095ea7b3600052336020526000196040526020803803606039602060006060601c826060515af161003057600080fd5b600080603a3d393df3";
    }

    function _computePodAddress(bytes32 salt) private view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(_podCreationCode()))
        );

        return address(uint160(uint256(hash)));
    }

    modifier onlyKeeper() {
        if (msg.sender != keeper) revert Errors.OnlyKeeper();
        _;
    }
}
