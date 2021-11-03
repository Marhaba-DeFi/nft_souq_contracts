// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC1155Factory.sol';
import './interfaces/IMedia.sol';
import './interfaces/IMarket.sol';
import './ERC721Factory.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Media is IMedia {
    using SafeMath for uint256;

    address private _ERC1155Address;
    address private _marketAddress;
    address private _ERC721Address;

    uint256 private _tokenCounter;

    // TokenHash => tokenID
    mapping(bytes32 => uint256) private _tokenHashToTokenID;

    // tokenID => Owner
    mapping(uint256 => address) public nftToOwners;

    // tokenID => Creator
    mapping(uint256 => address) nftToCreators;

    // tokenID => Token
    mapping(uint256 => MediaInfo) tokenIDToToken;

    modifier whenTokenExist(uint256 _tokenID) {
        require(tokenIDToToken[_tokenID]._creator != address(0), "Media: The Token Doesn't Exist!");
        _;
    }

    // modifier onlyApprovedOrOwner(address spender, uint256 _tokenID) {
    //     require(_isApprovedOrOwner(spender, _tokenID), 'Media: Only approved or owner');
    //     _;
    // }

    constructor(
        address _ERC1155,
        address _ERC721,
        address _market
    ) {
        require(_ERC1155 != address(0), 'Media: Invalid Address!');
        require(_ERC721 != address(0), 'Media: Invalid Address!');
        require(_market != address(0), 'Media: Invalid Address!');

        _ERC1155Address = _ERC1155;
        _ERC721Address = _ERC721;
        _marketAddress = _market;
    }

    function mintToken(MediaData memory data) external payable override returns (uint256) {
        require(data.collaborators.length == data.percentages.length, 'Media: Collaborators Info is not correct');

        bool _isFungible = data.totalSupply > 1 ? true : false;

        // verify sum of collaborators percentages needs to be less then or equals to 100
        uint256 sumOfCollabRoyalty = 0;
        for (uint256 index = 0; index < data.collaborators.length; index++) {
            sumOfCollabRoyalty = sumOfCollabRoyalty.add(data.percentages[index]);
        }
        require(sumOfCollabRoyalty <= 10, 'Media: Sum of Collaborators Percentages can be maximum 10');

        // Calculate hash of the Token
        bytes32 tokenHash = keccak256(abi.encodePacked(data.uri, data.title, data.totalSupply));

        // Check if Token with same data exists
        require(_tokenHashToTokenID[tokenHash] == 0, 'Media: Token With Same Data Already Exist!');

        _tokenCounter++;

        // Store the hash
        _tokenHashToTokenID[tokenHash] = _tokenCounter;

        // if token supply is 1 means we need to mint ERC 721 otherwise ERC 1155
        if (_isFungible) {
            ERC1155Factory(_ERC1155Address).mint(_tokenCounter, msg.sender, data.totalSupply);
        } else {
            ERC721Factory(_ERC721Address).mint(_tokenCounter, msg.sender);
            nftToOwners[_tokenCounter] = msg.sender;
        }

        nftToCreators[_tokenCounter] = msg.sender;

        MediaInfo memory newToken = MediaInfo(_tokenCounter, msg.sender, msg.sender, data.uri, data.title, _isFungible);
        // Hold token info
        tokenIDToToken[_tokenCounter] = newToken;

        // add collabs, percentages and sum of percentage
        IMarket.Collaborators memory newTokenColab = IMarket.Collaborators(
            data.collaborators,
            data.percentages,
            sumOfCollabRoyalty == 0 ? true : false
        );
        // route to market contract
        IMarket(_marketAddress).setCollaborators(_tokenCounter, newTokenColab);
        IMarket(_marketAddress).setRoyaltyPoints(_tokenCounter, data.royaltyPoints);

        // Put token on sale asa token got minted
        Iutils.Ask memory _ask = Iutils.Ask(
            data._reserveAmount,
            data._askAmount,
            data.totalSupply,
            data.currencyAsked,
            data.askType,
            0,
            0,
            address(0),
            data._duation
        );
        IMarket(_marketAddress).setAsk(_tokenCounter, _ask);

        // fire events
        emit MintToken(
            _tokenCounter,
            _isFungible,
            data.uri,
            data.title,
            data.totalSupply,
            data.royaltyPoints,
            data.collaborators,
            data.percentages
        );

        emit TokenCounter(_tokenCounter);

        return _tokenCounter;
    }

    /**
     * @notice This method is used to Get Token of _tokenID
     *
     * @param _tokenID TokenID of the Token to get
     *
     * @return Token The Token
     */
    function getToken(uint256 _tokenID) public view override whenTokenExist(_tokenID) returns (MediaInfo memory) {
        return tokenIDToToken[_tokenID];
    }

    function getTotalNumberOfNFT() external view returns (uint256) {
        return _tokenCounter;
    }

    function setBid(uint256 _tokenID, Iutils.Bid calldata bid)
        external
        payable
        override
        whenTokenExist(_tokenID)
        returns (bool)
    {
        address _owner = tokenIDToToken[_tokenID]._currentOwner;
        require(msg.sender == bid._bidder, 'Media: Bidder must be msg sender');
        require(bid._bidder != address(0), 'Media: bidder cannot be 0 address');
        require(_owner != msg.sender, "Media: The Token Owner Can't Bid!");

        MediaInfo memory token = tokenIDToToken[_tokenID];
        if (token._isFungible) {
            require(
                ERC1155Factory(_ERC1155Address).balanceOf(_owner, _tokenID) >= bid._bidAmount,
                'Media: The Owner Does Not Have That Much Tokens!'
            );
        } else {
            require(bid._bidAmount == 1, 'Media: Only 1 Token Is Available');
            require(nftToOwners[_tokenID] == _owner, 'Media: Invalid Owner Provided!');
        }

        bool tokenSold = IMarket(_marketAddress).setBid(_tokenID, msg.sender, bid, _owner, nftToCreators[_tokenID]);
        if (tokenSold) _transfer(_tokenID, _owner, bid._recipient, bid._bidAmount);
        return true;
    }

    /**
     * @notice see IMedia
     */
    function setAsk(uint256 _tokenID, Iutils.Ask memory ask) public override {
        IMarket(_marketAddress).setAsk(_tokenID, ask);
    }

    function removeBid(uint256 _tokenID) external override whenTokenExist(_tokenID) {
        IMarket(_marketAddress).removeBid(_tokenID, msg.sender);
    }

    function endAuction(uint256 _tokenID) external override whenTokenExist(_tokenID) returns (bool) {
        // TODO check either token is of type auction or not
        address _owner = tokenIDToToken[_tokenID]._currentOwner;
        address _creator = nftToCreators[_tokenID];
        IMarket(_marketAddress).endAuction(_tokenID, _owner, _creator);

        return true;
    }

    function cancelAuction(uint256 _tokenID) external override returns (bool) {
        require(
            tokenIDToToken[_tokenID]._currentOwner == msg.sender,
            'Can only be called by auction creator or curator'
        );
        IMarket(_marketAddress).cancelAuction(_tokenID);
        return true;
    }

    function setAdminAddress(address _adminAddress) external returns (bool) {
        IMarket(_marketAddress).setAdminAddress(_adminAddress);
        return true;
    }

    function getAdminCommissionPercentage() external view returns (uint256) {
        return IMarket(_marketAddress).getCommissionPercentage();
    }

    function setCommissionPercentage(uint8 _newCommissionPercentage) external returns (bool) {
        // TODO uncomment before moving to livenet
        // require(
        //     msg.sender == IMarket(_marketAddress).getAdminAddress(),
        //     'Media: Only Admin Can Set Commission Percentage!'
        // );
        require(_newCommissionPercentage > 0, 'Media: Invalid Commission Percentage');
        require(_newCommissionPercentage <= 100, 'Media: Commission Percentage Must Be Less Than 100!');

        IMarket(_marketAddress).setCommissionPercentage(_newCommissionPercentage);
        return true;
    }

    /**
     * @dev See {IMedia}
     */
    function transfer(
        uint256 _tokenID,
        address _recipient,
        uint256 _amount
    ) external override whenTokenExist(_tokenID) returns (bool) {
        MediaInfo memory mediainfo = tokenIDToToken[_tokenID];
        if (mediainfo._isFungible) {
            require(
                ERC1155Factory(_ERC1155Address).balanceOf(msg.sender, _tokenID) >= _amount,
                "Media: You Don't have The Tokens!"
            );
        } else {
            require(nftToOwners[_tokenID] == msg.sender, 'Media: Only Owner Can Transfer!');
        }

        _transfer(_tokenID, msg.sender, _recipient, _amount);
        return true;
    }

    function _transfer(
        uint256 _tokenID,
        address _owner,
        address _recipient,
        uint256 _amount
    ) internal {
        if (tokenIDToToken[_tokenID]._isFungible) {
            ERC1155Factory(_ERC1155Address).transferFrom(_owner, _recipient, _tokenID, _amount);
        } else {
            ERC721Factory(_ERC721Address).transferFrom(_owner, _recipient, _tokenID);
            nftToOwners[_tokenID] = _recipient;
        }
        tokenIDToToken[_tokenID]._currentOwner = _recipient;
        emit Transfer(_tokenID, _owner, _recipient, _amount);
    }
}
