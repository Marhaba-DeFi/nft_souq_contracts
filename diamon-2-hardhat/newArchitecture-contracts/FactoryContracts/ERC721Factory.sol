// SPDX-License-Identifier: MIT
/**
 * ERC721FactoryFacet is used to mint NFTs that are ERC721 compliant.
 * The mint function can only be called from souq Media contract. 
 * It is initialized with name and symbol and default royalty. 
 * 
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC721 factory contract
 * @dev This contract inherits from ERC721 openzeppelin contract, openzeppelin ERC721Enumerable, 
 * pausable, ERC721URIStorage and ERC2981 royalty contracts.
 */
contract SouqERC721 is ERC721, ERC721Enumerable, ERC721URIStorage, ERC2981, Pausable, Ownable {
    // Mapping from token ID to creator address
    mapping(uint256 => address) public _creators;

	/**
     * @dev Initializes the contract by setting a `name` and a `symbol` and default royalty to the token collection.
     */
    constructor (
		string memory _name, 
		string memory _symbol, 
		address royaltyReceiver, 
		uint96 _royaltyFeesInBips
		) 
		ERC721(_name, _symbol) {
        bytes memory name = bytes(_name); // Uses memory
        bytes memory symbol = bytes(_symbol);
        require( name.length != 0 && symbol.length != 0, "ERC721: Choose a name and symbol");
        _setDefaultRoyalty(royaltyReceiver, _royaltyFeesInBips);
    }

	/**
	* @dev pause function to pause minting. 
	 */
	function pause() public onlyOwner {
        _pause();
    }

	/**
	* @dev unpause function to resume minting. 
	 */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
	 * @notice This function is used for minting new NFT in the market.
     * @param tokenId tokenId
	 * @param creator address of the owner and creator of the NFT
	 * @param uri tokenURI
	 * @param royaltyReceiver an array of address that will recieve royalty. Max upto 5.
	 * @param tokenRoyaltyInBips an array of royalty percentages. It should match the number of reciever addresses. Max upto 5.
	 * @dev safemint() for minting the tokens.
	 * @dev internal setTokenURI() to set the token URI for the minted token
	 * @dev internal setTokenRoyalty() to set the rolayty at token level. 
	 */
    function safeMint(
		address creator, 
		string memory uri, 
		uint256 tokenId, 
		address royaltyReceiver, 
		uint96 tokenRoyaltyInBips
	) 
		public onlyOwner whenNotPaused {
        _safeMint(creator, tokenId);
        _setTokenURI(tokenId, uri);
        _creators[tokenId] = creator ;
        _setTokenRoyalty(tokenId, royaltyReceiver, tokenRoyaltyInBips);
    }

    function _beforeTokenTransfer(
		address from, 
		address to, 
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

	/**
	 * @notice This function is used for burning an existing NFT.
	 * @dev _burn is an inherited function from ERC721.
	 * Requirements:
     *
     * - `tokenId` must exist.
	 */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        delete _creators[tokenId];
    }

    function tokenURI(uint256 tokenId) 
		public view 
		override(ERC721, ERC721URIStorage) 
		returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)  public {
        require(msg.sender == _creators[tokenId], "ERC721: Not the creator of this token");
        require(msg.sender ==  ERC721.ownerOf(tokenId), "ERC721: Not the owner of this token");
        _setTokenURI(tokenId, _tokenURI);
    }

    function supportsInterface(bytes4 interfaceId) 
	public view 
	override(ERC721, ERC2981, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}