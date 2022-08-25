
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC721A factory contract
 * @dev This contract inherits from ERC721A Azuki smart contract, openzeppelin pausable 
 * and ERC2981 royalty contracts.
 * ERC721A bulks mints NFTs while saving considerable gas by eliminating enumarable function
 */
contract ERC721AFactory is ERC721A, Ownable {
	string public baseURI = "";

    bool public whitelistEnabled = false;
    mapping(address => bool) public whitelist;

	constructor(
        string memory name_, 
        string memory symbol_
        )
        ERC721A(name_, symbol_)
    {
        bytes memory validateName = bytes(name_); // Uses memory
        bytes memory validateSymbol = bytes(symbol_);
        require( validateName.length != 0 && validateSymbol.length != 0, "ERC721A: Choose a name and symbol");
    }

    /**
    * @notice This function is used fot minting.
    * @dev 'msg.sender' will pass the 'quantity' and address of the creator.
    */
    function mint(
        uint256 _quantity, 
        address _creator
    ) public {
        if(whitelistEnabled == false) {
            require(msg.sender == owner(), "Address not whitelisted");
        }
        if(whitelistEnabled == true) {
            require(whitelist[_msgSender()], "Address not whitelisted");
        }
        _safeMint(_creator, _quantity);
    }

	/**
	 * @dev Returns the base URI of the contract
	 */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

	/**
	 * @dev Set the base URI of the contract. Only owner and Media contract(if configured)
	 * can call this function.
	 */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }
}