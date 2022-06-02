// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155/ERC1155Facet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./LibERC1155FactoryStorage.sol";
import "../../libraries/LibURI.sol";

contract ERC1155FactoryFacet is ERC1155Facet {

    using Strings for uint256;
    modifier onlyMediaCaller() {
        require(
            msg.sender == s._mediaContract,
            "ERC1155Factory: Unauthorized Access!"
        );
        _;
    }

    function erc1155FactoryFacetInit(
    string memory name_,
    string memory symbol_,
    string memory baseURI_
    ) external{
     LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
     LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
     require(
      bytes(es.name).length == 0 &&
      bytes(es.symbol).length == 0 &&
      bytes(es._baseURI).length ==0,
      "ALREADY_INITIALIZED"
    );

     require(
      bytes(name_).length != 0 &&
      bytes(symbol_).length != 0,
      "INVALID_PARAMS"
    );


    require(msg.sender == ds.contractOwner, "Must own the contract.");

    es.name = name_;
    es.symbol = symbol_;
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
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        es._tokenURIs[tokenId] = _tokenURI;
    }

    function removeTokenUrl(uint256 tokenId) external onlyMediaCaller {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        delete es._tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        es._baseURI = baseURI_;
    }

     /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURL() public view virtual returns (string memory) {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        return es._baseURI;
    }

    function uri(uint id) public view override virtual returns (string memory) {
        return tokenURL(id);
    }


    function tokenURL(uint256 tokenId) internal view virtual returns (string memory) {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        string memory __tokenURI = es._tokenURIs[tokenId];
        string memory base = baseURL();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return __tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(__tokenURI).length > 0) {
            return LibURI.checkPrefix(base, __tokenURI);
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function mint(
        uint256 _tokenID,
        address _owner,
        uint256 _totalSupply,
        string memory _tokenURI
    ) external onlyMediaCaller {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        es.nftToOwners[_tokenID] = _owner;
        es.nftToCreators[_tokenID] = _owner;
        _mint(_owner, _tokenID, _totalSupply, "");
        setApprovalForAll(s._mediaContract, true);
        // _tokenUri is optional but will set if nft owner supply the details
        // 42 is the ipfs hash length that we sent from FE
        // if length is not 42 means, its url and add it as token url
        if ( bytes(_tokenURI).length != 42 )
        _setTokenURI(_tokenID, _tokenURI);
    }

    /**
     * @notice This Method is used to Transfer Token
     * @dev This method is used while Direct Buy-Sell takes place
     *
     * @param _from Address of the Token Owner to transfer from
     * @param _to Address of the Token receiver
     * @param _tokenID TokenID of the Token to transfer
     * @param _amount Amount of Tokens to transfer, in case of Fungible Token transfer
     *
     * @return bool Transaction Status
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID,
        uint256 _amount
    ) external onlyMediaCaller returns (bool) {
        require(_to != address(0x0), "ERC1155Factory: _to must be non-zero.");

        // require(
        //     _from == _msgSender() || _operatorApprovals[_from][_msgSender()] == true,
        //     'ERC1155Factory: Need operator approval for 3rd party transfers.'
        // );

        safeTransferFrom(_from, _to, _tokenID, _amount, "");
        setApprovalForAll(s._mediaContract, true);
        return true;
    }
}
