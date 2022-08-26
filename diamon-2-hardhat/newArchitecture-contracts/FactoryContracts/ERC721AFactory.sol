
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
    uint256 mapSize = 0; //Keeps a count of white listed users. Max is 2000

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
            require(whitelist[msg.sender], "Address not whitelisted");
        }
        _safeMint(_creator, _quantity);
    }

    /**
	 * @dev set whitelisted users
	 */
    function setWhitelist(address[] calldata newAddresses) public onlyOwner {
        // At least one royaltyReceiver is required.
        require(newAddresses.length > 0, "No user details provided");
        // Check on the maximum size over which the for loop will run over.
        require(newAddresses.length < 2000, "Too many userss to whitelist");
        for (uint256 i = 0; i < newAddresses.length; i++) {
			require(mapSize < 2000, "Maximum Users already whitelisted");
            whitelist[newAddresses[i]] = true;
            mapSize++;
		}
    }

    /**
	 * @dev remove whitelisted users
	 */
    function removeWhitelist(address[] calldata currentAddresses) public onlyOwner {
        // At least one royaltyReceiver is required.
        require(currentAddresses.length > 0, "No user details provided");
        // Check on the maximum size over which the for loop will run over.
        require(currentAddresses.length <= 5, "Too many userss to whitelist");
        for (uint256 i = 0; i < currentAddresses.length; i++){
            delete whitelist[currentAddresses[i]];
            mapSize--;
		}
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