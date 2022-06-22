// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Souq1155 is Pausable, ERC1155 {
    
    address private _mediaContract;
    address public owner;

    mapping(uint256 => address) nftToCreators;
    mapping(uint256 => string) private uris;

    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC1155(name, symbol) {
        owner = msg.sender;
        bytes memory name = bytes(_name); // Uses memory
        bytes memory symbol = bytes(_symbol);
        require( name.length != 0 && symbol.length != 0, "ERC1155: Choose a name and symbol");
    }

    modifier onlyOwner (){
        require(msg.sender == owner || msg.sender == _mediaContract, "Not the owner");
        _;
    }

    function configureMedia(address _mediaContractAddress) external {
        require(
            _mediaContractAddress != address(0),
            "ERC1155Factory: Invalid Media Contract Address!"
        );

        _mediaContract = _mediaContractAddress;
    }

    function setURI(uint256 tokenId, string memory newuri) public onlyOwner {
        uris[tokenId] = newuri;
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return(uris[tokenId]);
    }

    function mint(address _to, string memory _uri, uint256 _id, uint256 _copies )
        public onlyOwner returns(uint256, uint256) {
        _mint(_to, _id, _copies, "");
        setURI(_id, _uri);
		nftToCreators[_id] = _to;
        return(_id, _copies);
    }

    function transfer(address _owner, address _reciever, uint256 _tokenId, uint256 _copies) external returns (bool){
        safeTransferFrom(_owner, _reciever, _tokenId, _copies, "");
        return true;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
        //TODO: create mapping for nft Creators
    }
}