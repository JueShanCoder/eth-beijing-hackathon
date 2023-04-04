pragma solidity ^0.8.0;

import "./interface/IERC5489.sol";

contract EnglishAuction {
  IERC5489 private _hnft;
  address payable private _owner; // 合约所有者地址
  address public highestBidder; // 当前最高出价者地址
  uint256 public highestBid; // 当前最高出价
  uint public auctionEndTime; // 拍卖结束时间

  mapping(address => uint256) pendingReturns; // 用于进行退款的 mapping

  bool ended; // 判断是否已经结束拍卖

  event HighestBidIncreased(address bidder, uint256 amount); // 最高出价更新事件
  event AuctionEnded(address winner, uint256 amount); // 拍卖结束事件

  constructor(address hnftAddress, uint256 biddingTime) {
    _hnft = IERC5489(hnftAddress);
    _owner = payable(msg.sender);
    auctionEndTime = block.timestamp + biddingTime;
  }

  function bid() public payable {
    require(
      block.timestamp <= auctionEndTime,
      "Auction already ended."
    );
    require(
      msg.value > highestBid,
      "There already is a higher bid."
    );

    if (highestBid != 0) {
      // 如果之前已经有人进行了出价，将之前出价的货币返还给之前的出价者
      pendingReturns[highestBidder] += highestBid;
    }

    highestBidder = msg.sender;
    highestBid = msg.value;
    emit HighestBidIncreased(msg.sender, msg.value);
  }

  function withdraw() public returns (bool) {
    uint256 amount = pendingReturns[msg.sender];
    if (amount > 0) {
      pendingReturns[msg.sender] = 0;

      if (!payable(msg.sender).send(amount)) {
        pendingReturns[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }

  function endAuction() public {
    require(msg.sender == _owner, "Call not made by owner.");
    require(!ended, "Auction already ended.");

    ended = true;

    emit AuctionEnded(highestBidder, highestBid);

    // 将 HNFT 设定为出价者的 Owner
    _hnft.transferOwnership(highestBidder);
  }

  function getHNFTAddress() public view returns (address) {
    return address(_hnft);
  }
}
