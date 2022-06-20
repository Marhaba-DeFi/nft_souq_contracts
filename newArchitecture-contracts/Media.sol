// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Souq1155} from "./FactoryContracts/ERC1155Factory.sol";
import {SouqERC721} from "./FactoryContracts/ERC721Factory.sol";
import "./marketplace.sol";

contract Media is Ownable {

    function mintToken(
            address _to,
            uint256 _id,
            string memory _contractType,
            address _collection,
            uint256 _totalSupply,
            string memory _uri
        )
        external
        returns (uint256)
    {
        bool _isFungible = keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155"))) ? true : false;

        // if token supply is 1 means we need to mint ERC 721 otherwise ERC 1155
        if (_isFungible) {
            Souq1155(_collection).mint(
                 _to,
                 _id,
                _totalSupply,
                _uri
            );
        } else {
            SouqERC721(_collection).safeMint(
                    _to, 
                    _uri, 
                    _id
                );
        }

        return _id;
    }
}