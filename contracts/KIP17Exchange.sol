// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.5.0;

import "@klaytn/contracts/math/SafeMath.sol";
import "./Ownable.sol";
import "./KIP17Royalty.sol";

contract KIP17ExChange is Ownable{

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    address payable feeCollector;
    uint256 public feeRatio;

    struct Sale{
        address payable seller;
        uint256 price;
    }

    constructor() public{
        feeCollector = msg.sender;
        feeRatio = 50;
    }

    mapping(address => mapping(uint256=>Sale)) private _sales;

    event SalePlaced(address indexed kip17Contract, uint256 indexed tokenId, address indexed owner, uint256 price);
    event SaleCancelled(address indexed kip17Contract, uint256 indexed tokenId, address indexed owner);
    event ChangePrice(address indexed kip17Contract, uint256 indexed tokenId, uint256 price);
    event ChangeFeeCollector(address indexed operator, address oldFeeCollector, address newFeeCollector);
    event ChangeFeeRatio(address indexed operator, uint256 oldFeeRatio, uint256 newFeeRatio);

    function putOnSale(address kip17Contract, uint256 tokenId, uint256 price) public {

        address operator = msg.sender;
        address payable owner = address(uint160(KIP17Royalty(kip17Contract).ownerOf(tokenId)));

        require(
            owner == operator ||
            KIP17Royalty(kip17Contract).getApproved(tokenId) == operator ||
            KIP17Royalty(kip17Contract).isApprovedForAll(owner, operator)
            , "KIP17ExChange : not owner or approver");

        require(
            KIP17Royalty(kip17Contract).getApproved(tokenId) == address(this) ||
            KIP17Royalty(kip17Contract).isApprovedForAll(owner, address(this))
            , "KIP17Exchange : this exchange should be approved first"
        );

        _sales[kip17Contract][tokenId] = Sale(owner, price);

        emit SalePlaced(kip17Contract, tokenId, owner, price);
    }

    function getSaleInfo(address kip17Contract, uint256 tokenId) public view returns (address payable seller, uint256 price){
        Sale storage sale = _sales[kip17Contract][tokenId];

        return (sale.seller, sale.price);
    }

    function cancelSale(address kip17Contract, uint256 tokenId) public{
        Sale storage sale = _sales[kip17Contract][tokenId];
        address owner = msg.sender;

        require(sale.seller == owner, "KIP17Exchange : not seller");

        delete _sales[kip17Contract][tokenId];

        emit SaleCancelled(kip17Contract, tokenId, owner);
    }

    function changePrice(address kip17Contract, uint256 tokenId, uint256 price) public{
        Sale storage sale = _sales[kip17Contract][tokenId];

        require(sale.seller == msg.sender, "KIP17Exchange : not seller");
        _sales[kip17Contract][tokenId].price = price;

        emit ChangePrice(kip17Contract, tokenId, price);
    }

    function buyNFT(address kip17Contract, uint256 tokenId) public payable{
        Sale storage sale = _sales[kip17Contract][tokenId];

        require(msg.value == sale.price, "KIP17Exchange : price not matched");
        require(msg.sender != sale.seller, "KIP17Exchange : This is yours");

        address payable buyer = msg.sender;
        (address payable royaltyReceiver, uint256 royaltyAmount) = KIP17Royalty(kip17Contract).getRoyalty(tokenId, sale.price);

        KIP17Royalty(kip17Contract).transferFrom(sale.seller, buyer, tokenId);

        uint256 totalPrice = sale.price;
        uint256 fee = totalPrice / feeRatio;
        
        uint256 pay = totalPrice - fee - royaltyAmount;

        feeCollector.transfer(fee);
        royaltyReceiver.transfer(royaltyAmount);
        sale.seller.transfer(pay);

        delete _sales[kip17Contract][tokenId];
    }

    function changeFeeCollector(address payable newFeeCollector) public onlyOwner{
        emit ChangeFeeCollector(msg.sender, feeCollector, newFeeCollector);
        feeCollector = newFeeCollector;
    }

    function changeFeeRatio(uint256 _newFeeRatio) public onlyOwner{
        require(_newFeeRatio <= 250, "KIP17Exchange : Max Fee Ratio : 10%");
        require(_newFeeRatio > 0, "KIP17Exchange : cannot set zero or minus");

        emit ChangeFeeRatio(msg.sender, feeRatio, _newFeeRatio);

        feeRatio = _newFeeRatio;
    }

}
