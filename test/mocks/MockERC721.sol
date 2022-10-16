// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { ERC721 } from "solmate/tokens/ERC721.sol";
import { LibString } from "solmate/utils/LibString.sol";

contract MockERC721 is ERC721 {
    using LibString for uint256;

    string private _baseUri;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_
    ) ERC721(name_, symbol_) {
        _baseUri = baseUri_;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(_baseUri, id.toString()));
    }

    function mint(address to, uint256 id) external {
        _safeMint(to, id);
    }

    function burn(uint256 id) external {
        _burn(id);
    }
}
