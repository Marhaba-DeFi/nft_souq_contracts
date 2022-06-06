// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../ERC721/ERC721Facet.sol";
import "./LibERC721FactoryStorage.sol";
import "../../libraries/LibURI.sol";

contract ERC721FactoryFacet is ERC721Facet {
    using Strings for uint256;
    event BaseUriChanged(string newBaseURI);

    modifier onlyMediaCaller() {
        require(
            msg.sender == s._mediaContract,
            "ERC721Factory: Unauthorized Access!"
        );
        _;
    }

       /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function erc721FactoryFacetInit(
    string memory name_,
    string memory symbol_,
    string memory baseURI_
  ) external {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

    require(
      bytes(es._name).length == 0 &&
      bytes(es._symbol).length == 0 &&
      bytes(es._baseURI).length ==0,
      "ALREADY_INITIALIZED"
    );

    require(
      bytes(name_).length != 0 &&
      bytes(symbol_).length != 0,
      "INVALID_PARAMS"
    );

    require(msg.sender == ds.contractOwner, "Must own the contract.");

    es._name = name_;
    es._symbol = symbol_;
    _setBaseURI(baseURI_);
  }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();
        es._tokenURIs[tokenId] = _tokenURI;
    }

    function removeTokenUri(uint256 tokenId) external onlyMediaCaller{
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();
        delete es._tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();
        es._baseURI = baseURI_;
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() internal view virtual returns (string memory) {
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();
        return es._baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        string memory _tokenURI = es._tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return LibURI.checkPrefix(base, _tokenURI);
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /* 
    @notice This function is used for minting 
     new NFT in the market.
    @dev 'msg.sender' will pass the '_tokenID' and 
     the respective NFT details.
    */
    function mint(uint256 _tokenID, address _creator, string memory _tokenURI) external onlyMediaCaller {
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        es.nftToOwners[_tokenID] = _creator;
        es.nftToCreators[_tokenID] = _creator;
        _safeMint(_creator, _tokenID);
        _approve(s._mediaContract, _tokenID);
        // _tokenUri is optional but will set if nft owner supply the details
        // 42 is the ipfs hash length that we sent from FE
        // if length is not 42 means, its url and add it as token url
        if ( bytes(_tokenURI).length != 42 )
        _setTokenURI(_tokenID, _tokenURI);
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

        _approve(s._mediaContract, _tokenID);
        es.nftToOwners[_tokenID] = _recipient;
    }
}
