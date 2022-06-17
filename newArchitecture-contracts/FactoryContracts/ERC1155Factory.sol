// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract contract1155 is Ownable, Pausable, ERC1155 {
   using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    mapping(uint256 => address) nftToCreators;
    mapping(uint256 => string) private uris;

    constructor(
        string memory name, 
        string memory symbol
    ) ERC1155(name, symbol) {}

    function setURI(uint256 _tokenId, string memory _newuri) public onlyOwner {
        uris[_tokenId] = _newuri;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return(uris[_tokenId]);
    }

    function mint(uint256 _copies, string memory _uri)
        public returns(uint256, uint256) {

        uint256 id = tokenIdCounter.current();
        tokenIdCounter.increment();

        _mint(msg.sender, id, _copies, "");
        setURI(id, _uri);
		nftToCreators[id] = msg.sender;
        return(id, _copies);
    }

    function transfer(address _owner, address _reciever, uint256 _tokenId, uint256 _copies) external returns (bool){
        safeTransferFrom(_owner, _reciever, _tokenId, _copies, "");
        return true;
    }


}