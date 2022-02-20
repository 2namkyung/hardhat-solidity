// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.5.0;

import "@klaytn/contracts/drafts/Counters.sol";
import "@klaytn/contracts/token/KIP17/KIP17Full.sol";
import "@klaytn/contracts/token/KIP17/KIP17Metadata.sol";

contract KIP17Royalty is KIP17Metadata, KIP17Full{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address marketContract;

    struct RoyaltyInfo{
        address payable royaltyReceiver;
        uint96 royaltyRatio;
    }

    mapping(uint256=>RoyaltyInfo) private idToRoyaltyInfo;

    constructor(address _marketContract) public KIP17Full("NK", "FS") {
        marketContract = _marketContract;
    }

    function setRoyalty(uint _tokenId, address payable _royaltyRecevier, uint96 _royaltyRatio) public{
        require(msg.sender==ownerOf(_tokenId), "This is not yours");
        require(_royaltyRatio >= 0 && _royaltyRatio <= 5000, "0% <= royaltyRatio <= 50%");

        idToRoyaltyInfo[_tokenId].royaltyReceiver = _royaltyRecevier;
        idToRoyaltyInfo[_tokenId].royaltyRatio = _royaltyRatio;
    }

    function getRoyalty(uint256 _tokenId, uint256 _salePrice) external view returns(address payable royaltyReceiver, uint256 royaltyAmount){
       
       royaltyReceiver = idToRoyaltyInfo[_tokenId].royaltyReceiver;
       royaltyAmount = _salePrice * idToRoyaltyInfo[_tokenId].royaltyRatio / 10000;
    }

    function createToken(string memory tokenURI, uint96 _royaltyRatio) public returns (uint){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(marketContract, true);

        if(_royaltyRatio >=0 && _royaltyRatio <=5000){
            setRoyalty(newItemId, msg.sender, _royaltyRatio);
        }else{
            setRoyalty(newItemId, msg.sender, 0);
        }

        return newItemId;
    }

}