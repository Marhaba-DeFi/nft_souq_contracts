// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/**
 * @title ERC721 factory contract
 * @dev This contract inherits from ERC721 openzeppelin contract, openzeppelin ERC721Enumerable, 
 * pausable, ERC721URIStorage and ERC2981 royalty contracts.
 */
contract SouqERC721 is ERC721, ERC721Enumerable, ERC721URIStorage, ERC2981, Pausable {
    address private _mediaContract;
    address public owner;

    // Mapping from token ID to creator address
    mapping(uint256 => address) public _creators;

    constructor (
		string memory _name, 
		string memory _symbol, 
		address royaltyReceiver, 
		uint96 _royaltyFeesInBips
		) 
		ERC721(_name, _symbol) {
        owner = msg.sender;
        bytes memory name = bytes(_name); // Uses memory
        bytes memory symbol = bytes(_symbol);
        require( name.length != 0 && symbol.length != 0, "ERC721: Choose a name and symbol");
        _setDefaultRoyalty(royaltyReceiver, _royaltyFeesInBips);
    }

    modifier mediaOrOwner() {
        require(msg.sender == owner || msg.sender == _mediaContract, "Not media nor owner");
        _;
    }

    modifier onlyOwner ()
	{
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyMedia ()
	{
        require(msg.sender == _mediaContract, "Not the media contract");
        _;
    }

	/**
	* @dev Configure media contract 
	 */
    function configureMedia(address _mediaContractAddress) external onlyOwner 
	{
        require(
            _mediaContractAddress != address(0),
            "ERC721Factory: Invalid Media Contract Address!"
        );

        _mediaContract = _mediaContractAddress;
    }

	/**
	* @dev pause function to pause minting. 
	 */
	function pause() public onlyOwner 
	{
        _pause();
    }

	/**
	* @dev unpause function to resume minting. 
	 */
    function unpause() public onlyOwner 
	{
        _unpause();
    }

    /**
    * @dev This function is used fot minting.
	* Mapping of Creators to Token Id
	* Set Royalty. If Royalty is not provided, then _tokenRoyaltyInBips should be zero. 
    */
    function safeMint(
		address _to, 
		string memory _uri, 
		uint256 _id, 
		address royaltyReceiver, 
		uint96 _tokenRoyaltyInBips
	) 
		public mediaOrOwner whenNotPaused
	{
        _safeMint(_to, _id);
        _setTokenURI(_id, _uri);
        _creators[_id] = _to ;
        _setTokenRoyalty(_id, royaltyReceiver, _tokenRoyaltyInBips);
    }

    function _beforeTokenTransfer(
		address from, 
		address to, 
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) 
	{
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) 
	{
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

    function setTokenURI(uint256 tokenId, string memory _tokenURI)  public 
	{
        require(msg.sender == _creators[tokenId], "ERC721: Not the creator of this token");
        require(msg.sender ==  ERC721.ownerOf(tokenId), "ERC721: Not the owner of this token");
        _setTokenURI(tokenId, _tokenURI);
    }

    function supportsInterface(bytes4 interfaceId) 
	public view 
	override(ERC721, ERC2981, ERC721Enumerable) returns (bool)
	{
        return super.supportsInterface(interfaceId);
    }
}