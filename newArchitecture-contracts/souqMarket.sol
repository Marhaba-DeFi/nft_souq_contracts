// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MarketPlace is EIP712{
    using SafeMath for uint256;

    constructor (string memory _name, string memory _version) EIP712 (_name, _version) {

    }

    modifier onlyMediaCaller() {
        require(msg.sender == _mediaContract, "Market: Unauthorized Access!");
        _;
    }

    // tokenID => creator's Royalty Percentage
    mapping(uint256 => uint8) private tokenRoyaltyPercentage;

    // tokenID => { collaboratorsAddresses[] , percentages[] }
    mapping(uint256 => Collaborators) private tokenCollaborators;

    // Approved erc20 tokens only acciable by admin of souq
    mapping(address => bool) private approvedCurrency;

    /**
     * @dev See {IMarket}
     */
    function setCollaborators(
        uint256 _tokenID,
        Collaborators calldata _collaborators
    ) external override onlyMediaCaller {
        tokenCollaborators[_tokenID] = _collaborators;
    }

    /**
     * @dev See {IMarket}
     */
    function setRoyaltyPoints(uint256 _tokenID, uint8 _royaltyPoints)
    external
    override
    onlyMediaCaller
    {
        tokenRoyaltyPercentage[_tokenID] = _royaltyPoints;
        emit RoyaltyUpdated(_tokenID, _royaltyPoints);
    }

    function hashOffer(address collection, uint256 tokenId, uint256 bidAmount ) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(keccak256("Bid(address collection,uint256 tokenId,uint256 bidAmount)"),
            collection,
            tokenId,
            bidAmount
            )));
    }

    function _verify(address _nftContAddress, uint256 _tokenId, uint256 _bid, bytes memory _signature, address _signer) internal view returns (bool) {
        bytes32  _structHash = hashOffer(_collection,_tokenId,_bidAmount);
        return (ECDSA.recover(_structHash, _signature) ==_signer);
    }

    function Accept(
        string memory _contractType,
        address _collection,
        address _winner,
        address _erc20Address,
        address _owner,
        address[] memory _rewardAccounts,
        uint256 _bidAmount,
        uint256[] memory _tokenIdAmount,
        uint256[] memory _shares,
        bytes memory _signatureOfBidder,
        bytes memory _signedRewardAccounts
    ) public {
        require(_verify(_collection, _tokenIdAmount[0], _bidAmount, _signatureOfBidder, _winner), "The winner signature is not valid");
        require (hasRole(SIGNER_ROLE,ECDSA.recover(keccak256(abi.encodePacked(_rewardAccounts)), _signedRewardAccounts)), "Reward accounts are not valid");
        {
            uint256 counter = _bidAmount;
            ERC20 erc20 = ERC20(_erc20Address);
            require(erc20.balanceOf(_winner) >= _bidAmount, "Not enough weth in the winner wallet");
            for(uint256 i = 0; i< _shares.length ; i++ ){
                require(counter >= _shares[i], "The shares are greater than bid amount");
                counter = counter - _shares[i];
                erc20.transferFrom(_winner, _rewardAccounts[i], _shares[i]);
            }
        }
        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC721")))) {
            ERC721 erc721 = ERC721(_collection);
            erc721.transferFrom(_owner,_winner, _tokenIdAmount[0]);
        }
        if (keccak256(abi.encodePacked((_contractType))) == keccak256(abi.encodePacked(("ERC1155")))) {
            ERC1155 erc1155 = ERC1155(_collection);
            erc1155.safeTransferFrom(_owner,_winner, _tokenIdAmount[0], _tokenIdAmount[1], "");
        }
    }
}