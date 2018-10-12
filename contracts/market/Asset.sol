pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../token/EIP20Interface.sol";

contract Asset {
  using SafeMath for uint;

  EIP20Interface bdn;

  string public assetId;
  uint public expectPrice;

  address public seller;

  address public buyer;
  string public buyerCdbAddress;
  string public buyerBoxAddress;

  address public referee;

  uint public paidPrice;

  event Paid(address mktId, string asset, address seller, address buyer, string buyerCdbAddress, string buyerBoxAddress);

  event Dealt(address mktId, string asset, address seller, uint val);

  constructor(address _bdn, address _referee, address _seller, string _assetId, uint _price) public {
    bdn = EIP20Interface(_bdn);
    referee = _referee;
    seller = _seller;
    assetId = _assetId;
    expectPrice = _price;
  }

  modifier onlyReferee {
    require(msg.sender == referee, "forbidden");
    _;
  }

  modifier onlyRefereeOrBuyer {
    bool isBuyer_ = isBuyer(msg.sender);
    require(isBuyer_ || msg.sender == referee, "forbidden");
    _;
  }

  /**
   * Before calling this method to buy an asset, the buyer should
   * call `BDNToken.approve(this_contract_address, price)` to approve
   * `this asset contract` to manipulate his allowance, since `this asset
   * contract` will role as a referee during the buying and selling process
   */
  function buy(string buyerCdbAddress_, string buyerBoxAddress_, uint price) public {
    if (price < expectPrice || buyer != address(0)) return;

    bdn.transferFrom(msg.sender, address(this), price);

    buyer = msg.sender;
    buyerCdbAddress = buyerCdbAddress_;
    buyerBoxAddress = buyerBoxAddress_;

    paidPrice = price;
    emit Paid(address(this), assetId, seller, buyer, buyerCdbAddress, buyerBoxAddress);
  }

  function transfer(address to, uint amount) public onlyReferee {
    bdn.transfer(to, amount);
  }

  function bdnAmount() public view returns(uint) {
    return bdn.balanceOf(address(this));
  }

  function isBuyer(address u) public view returns(bool) {
    return buyer == u;
  }

  function isBuyable() public view returns(bool) {
    return buyer == address(0);
  }

  function deal() public onlyRefereeOrBuyer {
    bdn.transfer(seller, paidPrice);
    emit Dealt(address(this), assetId, seller, paidPrice);
  }
}
