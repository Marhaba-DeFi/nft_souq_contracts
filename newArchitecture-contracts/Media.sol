// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Souq1155} from "./FactoryContracts/ERC1155Factory.sol";
import {SouqERC721} from "./FactoryContracts/ERC721Factory.sol";
import {SouqMarketPlace} from "./souqMarket.sol";

contract Media is Ownable {

	address marketContract;

    struct Collaborators {
        address[] _collaborators;
        uint96[] _collabFraction;
    }

	function configureMarketPlace(address _marketContract) external onlyOwner {
        require(
            _marketContract != address(0),
            "Media Contract: Invalid MarketPlace Contract Address!"
        );

        marketContract = _marketContract;
    }

    function mintToken(
            address _to,
            uint256 _id,
            string memory _contractType,
            address _collection,
            uint256 _copies,
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
				_uri,
                _id,
                _copies
                
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

	//SetCollaborators() to set collaborators in marketplace contract

      function _setCollaborators (address _nftAddress, uint256 _tokenID, Collaborators calldata _collaborators) public {

        require(SouqERC721(_nftAddress).ownerOf(_tokenID) == msg.sender, "Only token owner could call this function");
        SouqMarketPlace(marketContract).setCollaborators(_nftAddress, _tokenID, _collaborators);
      
      }

	//Authorise marketplace contract for all NFT tokens and ERC20 tokens

    function approveMarketFor721 (address _nftAddress) public {

        SouqERC721(_nftAddress).setApprovalForAll(marketContract, true);
    }

    function approveMarketFor1155 (address _nftAddress) public {

        Souq1155(_nftAddress).setApprovalForAll(marketContract, true);
    }

	//AcceptBid() 
	function acceptBid(
        string memory _contractType,
        address _nftContAddress,
        address _currencyAddress,
        address _seller,
        address _bidder,
        uint256 _tokenID,
        uint256 _bid,
        uint256 _copies,
        bytes memory _bidderSig,
        bytes memory _sellerSig
    ) public {
		SouqMarketPlace(marketContract).acceptBid(
			_contractType,
			_nftContAddress,
			_currencyAddress,
			_seller,
			_bidder,
			_tokenID,
			_bid,
            _copies,
			_bidderSig,
			_sellerSig
		);
	}
}