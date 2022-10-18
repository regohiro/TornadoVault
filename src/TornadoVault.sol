// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Pod } from "./Pod.sol";
import { ITornadoVault, Errors } from "./ITornadoVault.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { AutomationBase } from "lib/chainlink/contracts/src/v0.8/AutomationBase.sol";

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
        uint256 min,
        uint256 max
    ) external {
        if (_tokenIndex[token] != 0) revert Errors.TokenAlreadyAdded();

        _tokenIndex[token] = _tokenRules.length;
        _tokenRules.push(TokenRule(token, false, min, max));

        emit AddTokenRule(token, min, max);
    }

    function updateTokenRule(
        address token,
        bool disabled,
        uint256 min,
        uint256 max
    ) external {
        _tokenRules[_getTokenIndex(token)] = TokenRule(token, disabled, min, max);

        emit UpdateTokenRule(token, disabled, min, max);
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
            if (balance > _tokenRules[i].max) {
                actionTokens[num++] = ActionToken(
                    token,
                    Action.REMOVE,
                    (_tokenRules[i].max - _tokenRules[i].min) / 2
                );
            } else if (
                balance < _tokenRules[i].min && _podNonce[token].left < _podNonce[token].right
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
                address pod = address(new Pod{ salt: salt }(address(this), token));

                ERC20(token).transfer(pod, actionTokens[i].amount);
            } else if (actionTokens[i].action == Action.ADD) {
                bytes32 salt = keccak256(abi.encodePacked(token, _podNonce[token].left++));
                address pod = _computePodAddress(salt);

                ERC20(token).transferFrom(pod, address(this), actionTokens[i].amount);
            }
        }
    }

    function _computePodAddress(bytes32 salt) private view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(type(Pod).creationCode))
        );

        return address(uint160(uint256(hash)));
    }

    function _getTokenIndex(address token) private view returns (uint256 index) {
        if ((index = _tokenIndex[token]) == 0) revert Errors.TokenNotAdded();
    }

    modifier onlyKeeper() {
        if (msg.sender != keeper) revert Errors.OnlyKeeper();
        _;
    }
}
