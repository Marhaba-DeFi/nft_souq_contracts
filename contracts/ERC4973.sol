// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC4973} from "./interfaces/IERC4973.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


abstract contract ERC4973 is ERC165, IERC721Metadata, IERC4973 {
  using Strings for uint256;

  string private _name;
  string private _symbol;
  string public baseURI = "";

  mapping(uint256 => address) private _owners;

  /**
  * @dev Emitted when `BaseURI` is set.
  */
  event BaseURI(string uri);
  
  constructor(
    string memory name_,
    string memory symbol_
  ) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC4973).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the base URI of the contract
  */
  function _baseURI() internal view returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
	require(_exists(_tokenId), "SBT: URI query for nonexistent token");
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString())) : "";
  }


  function burn(uint256 _tokenId) public virtual override {
    require(msg.sender == ownerOf(_tokenId), "burn: sender must be owner");
    _burn(_tokenId);
  }

  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ownerOf: token doesn't exist");
    return owner;
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _mint(
    address to,
    uint256 tokenId
  ) internal virtual returns (uint256) {
    require(!_exists(tokenId), "mint: tokenID exists");
    _owners[tokenId] = to;
    emit Attest(to, tokenId);
    return tokenId;
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);

    delete _owners[tokenId];

    emit Revoke(owner, tokenId);
  }
}
