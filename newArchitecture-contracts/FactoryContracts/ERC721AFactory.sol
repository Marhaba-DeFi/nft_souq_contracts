// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract ERC721AFactory is ERC721A, Ownable {
    constructor(string memory name_, string memory symbol_)
        ERC721A(name_, symbol_)
    {}

    // tokenID => Creator
    mapping(uint256 => address) nftToCreators;

    /* 
    @notice This function is used fot minting 
     new NFT in the market.
    @dev 'msg.sender' will pass the 'quantity' to be minted and 
     the respective NFT details.
    */
    function mint(uint256 quantity, address _creator) external payable  {
        _safeMint(_creator, quantity);
    }

     /* 
    @notice This function is used fot Listing  
      NFT in the market.
    @dev 'msg.sender' will pass the '_tokenID' and 
     the 'Marketplace contract'.
    */
    function list(address to, uint256 tokenId) public {
        approve(to, tokenId);
    }
}