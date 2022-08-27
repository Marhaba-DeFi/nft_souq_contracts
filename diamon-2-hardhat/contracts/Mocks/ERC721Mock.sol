// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../ERC2981.sol";

contract ERC721Mock is ERC721, ERC2981 {
    constructor (
		string memory _name, 
		string memory _symbol, 
        bool defaultRoyalty,
		address[] memory royaltyReceiver, 
		uint96[] memory royaltyFeesInBips
    ) 
		ERC721(_name, _symbol) {
        bytes memory name = bytes(_name); // Uses memory
        bytes memory symbol = bytes(_symbol);
        require( name.length != 0 && symbol.length != 0, "ERC721: Choose a name and symbol");
        if(defaultRoyalty){
            _setDefaultRoyalty(royaltyReceiver, royaltyFeesInBips);
        }
    }
    function safeMint(
		address creator, 
        uint256 tokenId,
        bool tokenRoyalty,
		address[] memory royaltyReceiver, 
		uint96[] memory tokenRoyaltyInBips
	) public {
        _safeMint(creator, tokenId);
        //If Author royalty is set to true
        if(tokenRoyalty){
            _setTokenRoyalty(tokenId, royaltyReceiver, tokenRoyaltyInBips);
        }
    }

    function supportsInterface(bytes4 interfaceId) 
	public view 
	override(ERC721, ERC2981) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}