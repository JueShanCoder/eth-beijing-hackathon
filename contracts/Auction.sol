// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IERC5489.sol";

contract EnglishAuction {
    using SafeMath for uint256;

    IERC5489 public nft;
    // 拍卖结束的时间点
    uint256 public auctionEndTime;
    // 当前的最高出价
    uint256 public highestBid;
    // 当前的最高出价者
    address public highestBidder;
    // 拍卖室的所有者
    address public owner;
    // 出价人的出价记录
    mapping(address => uint256) public fundsByBidder;
    // 出价人的出价时间
    mapping(address => uint256) public bidTimes;
    // 拍卖是否已经结束
    bool ended;

    // 出价被接受时触发的事件
    event HighestBidIncreased(address bidder, uint256 amount);
    // 拍卖结束时触发的事件
    event AuctionEnded(address winner, uint256 amount);

    // 构造函数，接收拍卖时间和拍卖室所有者
    constructor(uint256 _biddingTime, address _owner) {
        // 设置拍卖结束的时间
        auctionEndTime = block.timestamp.add(_biddingTime);
        // 设置拍卖室的所有者
        owner = _owner;
    }

    // 出价函数
    function bid() public payable {
        // 检查拍卖是否已经结束
        require(block.timestamp <= auctionEndTime, "Auction already ended.");
        // 检查出价是否大于当前最高出价
        require(msg.value > highestBid, "There already is a higher bid.");
        // 检查用户的余额是否足够支付出价（考虑抵押）
        require(msg.sender.balance >= msg.value.sub(highestBid), "Not enough balance.");

        // 如果当前不是第一轮出价，将前一轮的出价返还给出价人
        if (highestBid != 0) {
            fundsByBidder[highestBidder] = fundsByBidder[highestBidder].add(highestBid);
        }

        // 更新最高出价和最高出价者的信息
        highestBid = msg.value;
        highestBidder = msg.sender;
        // 记录当前出价人的出价和出价时间
        fundsByBidder[msg.sender] = fundsByBidder[msg.sender].add(msg.value);
        bidTimes[msg.sender] = block.timestamp;

        // 触发出价成功事件
        emit HighestBidIncreased(msg.sender, msg.value);
    }
    
    // 出价人更新状态的函数，仅限最高出价者调用
    function statusUpdate() public {
        // 检查调用者是否最高出价者
        require(msg.sender == highestBidder, "Only the highest bidder can update status.");
        // 检查最高出价者上一次更新状态的时间是否至少为 30 秒以前
        require(bidTimes[msg.sender] + 30 seconds <= block.timestamp, "Wait for 30 seconds.");
        
        // 触发出价人状态更新事件
        emit StatusUpdated(highestBidder, highestBid, false);
    }

    // 出价人提取退款的函数
    function withdraw() public {
        // 检查拍卖是否结束
        require(block.timestamp > auctionEndTime, "Auction has not ended yet.");
        // 检查是否为最高出价者（最高出价者不允许退款）
        require(highestBidder != msg.sender, "You have won the auction. Cannot withdraw.");
        
        // 获取当前出价人已出价的金额
        uint256 amount = fundsByBidder[msg.sender];
        // 检查当前出价人已出价金额是否大于 0
        require(amount > 0, "Nothing to withdraw.");

        // 重置出价人的已出价金额为 0
        fundsByBidder[msg.sender] = 0;
        // 向当前出价人的账户中返还出价费用
        payable(msg.sender).transfer(amount);
    }

    // 结束拍卖并将出价金额发给拍卖室所有者
    function auctionEnd() public restricted {
        // 检查拍卖是否已经结束
        require(!ended, "AuctionEnd has already been called.");

        // 标记拍卖结束
        ended = true;
        
        // 向拍卖室所有者账户中支付拍卖价钱
        payable(owner).transfer(highestBid);
        
        // 触发拍卖结束事件和出价人状态更新事件
        emit AuctionEnded(highestBidder, highestBid);
        emit StatusUpdated(highestBidder, highestBid, true);
    }

    // 限制只有拍卖室所有者可以调用的函数修饰符
    modifier restricted() {
        // 检查当前调用者是否为拍卖室所有者
        require(msg.sender == owner, "Only the auction owner can end the auction.");
        // 检查当前时间是否已经超过拍卖结束时间
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        _;
    }
}
