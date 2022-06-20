// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {contract1155} from "./FactoryContracts/ERC1155Factory.sol";
import {SouqERC721} from "./FactoryContracts/ERC721Factory.sol";
import "./marketplace.sol";

contract Media is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    function mintToken(
            address _to,
            string memory _contractType,
            address _collection,
            uint256 _totalSupply,
            string memory _uri
        )
        external
        returns (uint256)
    {
        bool _isFungible = keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155"))) ? true : false;

        uint256 id = tokenIdCounter.current();
        tokenIdCounter.increment();

        // if token supply is 1 means we need to mint ERC 721 otherwise ERC 1155
        if (_isFungible) {
            contract1155(_collection).mint(
                 _to,
                 id,
                _totalSupply,
                _uri
            );
        } else {
            SouqERC721(_collection).safeMint(
                    _to, 
                    _uri, 
                    id
                );
        }

        return id;
    }
}