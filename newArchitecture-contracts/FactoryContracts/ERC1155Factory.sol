// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract contract1155 is Pausable, ERC1155 {
    
    address private mediaContract;
    address public owner;

    mapping(uint256 => address) nftToCreators;
    mapping(uint256 => string) private uris;

    constructor(
        string memory _name, 
        string memory _symbol,
        address _mediaContract
    ) ERC1155(name, symbol) {
        owner = msg.sender;
        mediaContract = _mediaContract;
        bytes memory name = bytes(_name); // Uses memory
        bytes memory symbol = bytes(_symbol);
        require( name.length != 0 && symbol.length != 0, "ERC1155: Choose a name and symbol");
    }

    modifier onlyOwner (){
        require(msg.sender == owner || msg.sender == mediaContract, "Not the owner");
        _;
    }

    function setURI(uint256 _tokenId, string memory _newuri) public onlyOwner {
        uris[_tokenId] = _newuri;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return(uris[_tokenId]);
    }

    function mint(address _to, uint256 _id, uint256 _copies, string memory _uri)
        public returns(uint256, uint256) {
        _mint(_to, _id, _copies, "");
        setURI(_id, _uri);
		nftToCreators[_id] = _to;
        return(_id, _copies);
    }

    function transfer(address _owner, address _reciever, uint256 _tokenId, uint256 _copies) external returns (bool){
        safeTransferFrom(_owner, _reciever, _tokenId, _copies, "");
        return true;
    }
}