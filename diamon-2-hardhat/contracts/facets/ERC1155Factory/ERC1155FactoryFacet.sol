// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155/ERC1155Facet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./LibERC1155FactoryStorage.sol";
import "../../libraries/LibURI.sol";

contract ERC1155FactoryFacet is ERC1155Facet, Pausable {

    using Strings for uint256;

    function erc1155FactoryFacetInit(
    string memory name_,
    string memory symbol_
    ) external{
     LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
     LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
     require(
      bytes(es.name).length == 0 &&
      bytes(es.symbol).length == 0,
      "ALREADY_INITIALIZED"
    );

     require(
      bytes(name_).length != 0 &&
      bytes(symbol_).length != 0,
      "INVALID_PARAMS"
    );


    es.name = name_;
    es.symbol = symbol_;
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

    function mint(
        uint256 _tokenID,
        address _owner,
        uint256 _totalSupply,
        string memory _tokenURI
    ) external {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        es.nftToOwners[_tokenID] = _owner;
        es.nftToCreators[_tokenID] = _owner;
        _mint(_owner, _tokenID, _totalSupply, "");
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
    ) external  returns (bool) {
        require(_to != address(0x0), "ERC1155Factory: _to must be non-zero.");
        safeTransferFrom(_from, _to, _tokenID, _amount, "");
        return true;
    }
}