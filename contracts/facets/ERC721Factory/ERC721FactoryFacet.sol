// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC721/ERC721Facet.sol";
import "./LibERC721FactoryStorage.sol";

contract ERC721FactoryFacet is ERC721Facet, Ownable {

    modifier onlyMediaCaller() {
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        require(
            msg.sender == es._mediaContract,
            "ERC721Factory: Unauthorized Access!"
        );
        _;
    }

    function configureMedia(address _mediaContractAddress) external onlyOwner {
        // TODO: Only Owner Modifier
        require(
            _mediaContractAddress != address(0),
            "ERC1155Factory: Invalid Media Contract Address!"
        );
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        
        require(
            es._mediaContract == address(0),
            "ERC1155Factory: Media Contract Alredy Configured!"
        );

        es._mediaContract = _mediaContractAddress;
    }

    /* 
    @notice This function is used fot minting 
     new NFT in the market.
    @dev 'msg.sender' will pass the '_tokenID' and 
     the respective NFT details.
    */
    function mint(uint256 _tokenID, address _creator) external onlyMediaCaller {
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        es.nftToOwners[_tokenID] = _creator;
        es.nftToCreators[_tokenID] = _creator;
        _safeMint(_creator, _tokenID);
        _approve(es._mediaContract, _tokenID);
    }

    /*
    @notice This function will transfer the Token 
     from the caller's address to the recipient address
    @dev Called the ERC721'_transfer' function to transfer 
     tokens from 'msg.sender'
    */
    function transfer(address _recipient, uint256 _tokenID)
        public
        onlyMediaCaller
    {
        require(_tokenID > 0, "ERC721Factory: Token Id should be non-zero");
        transferFrom(msg.sender, _recipient, _tokenID); // ERC721 transferFrom function called
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();
        
        es.nftToOwners[_tokenID] = _recipient;
    }

    /*
    @notice This function will transfer from the sender account
     to the recipient account but the caller have the allowence 
     to send the Token.
    @dev check the allowence limit for msg.sender before sending
     the token
    */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _tokenID
    ) public override onlyMediaCaller {
        require(_tokenID > 0, "ERC721Factory: Token Id should be non-zero");
        require(
            _isApprovedOrOwner(_msgSender(), _tokenID),
            "ERC721Factory: transfer caller is neither owner nor approved"
        );

        safeTransferFrom(_sender, _recipient, _tokenID); // ERC721 safeTransferFrom function called
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        _approve(es._mediaContract, _tokenID);
        es.nftToOwners[_tokenID] = _recipient;
    }
}
