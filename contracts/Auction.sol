// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IERC5489.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AuctionAndMicroPayment {
    using SafeMath for uint256;
    
    constructor() {
        owner = msg.sender;
    }

    struct Bid {
        uint256 amount;
        address bidder;
        address tokenContract;
        string  slotUri;
    }

    IERC5489 public nft;
    IERC20 public token;

    mapping(uint256 => Bid) public highestBid;

    address public owner;

    event HighestBidIncreased(uint256 hNFTId, Bid bid);
    event RefundPreviousBidIncreased(uint256 hNFTId, address tokenAddress, address refunder, uint256 amount);
    event PayOutIncreased(uint256 hNFTId, address payoutAddress, uint256 amount);

    function bid(uint256 hNFTId, address hNFTContractAddr, address tokenContractAddr,
                 uint256 fragmentAmout, string calldata slotUri) public {
        require(fragmentAmout > 0, "Bid amount must be greater than 0.");
        require(hNFTContractAddr != address(0) && tokenContractAddr != address(0), "The hnft and token contract can not be address(0).");

        uint256 bidAmount = highestBid[hNFTId].amount;
        if (bidAmount == 0) {
            bidSuccess(hNFTId, fragmentAmout, slotUri, false, hNFTContractAddr, tokenContractAddr);
        } else {
            require(checkLarger(fragmentAmout ,bidAmount), "The current bidding price is too low.");
            bidSuccess(hNFTId, fragmentAmout, slotUri, true, hNFTContractAddr, tokenContractAddr);
        }
    }

    function bidSuccess(uint256 hNFTId, uint256 fragmentAmout, 
                        string calldata slotUri, bool needFund, 
                        address hNFTContractAddr, address tokenContractAddr) private {
        nft = IERC5489(hNFTContractAddr);
        if (needFund) {
            // memory or storage ?
            Bid memory previousBid = highestBid[hNFTId];
            token = IERC20(previousBid.tokenContract);
            token.transfer(previousBid.bidder, previousBid.amount);
            // nft.revokeAuthorization(hNFTId, previousBid.bidder);
            emit RefundPreviousBidIncreased(hNFTId, previousBid.tokenContract, previousBid.bidder, previousBid.amount);
        }
 
        token = IERC20(tokenContractAddr);
        uint256 tokenAllowance = token.allowance(msg.sender, address(this));
        require(tokenAllowance >= fragmentAmout, "Insufficient token balance.");
        token.transferFrom(msg.sender, address(this), fragmentAmout);

        // nft.authorizeSlotTo(hNFTId, msg.sender);
        nft.setSlotUri(hNFTId, slotUri);
        highestBid[hNFTId] = Bid(fragmentAmout, msg.sender, tokenContractAddr, slotUri);
        
        emit HighestBidIncreased(hNFTId, highestBid[hNFTId]);
    }

    function payout(uint256 hNFTId, uint256 fragmentAmount) public {
        // TODO 添加广告主验签操作
        Bid memory payOutBid = highestBid[hNFTId];
        require(fragmentAmount <= payOutBid.amount, "The advertising sponsor is credit balance is insufficient.");

        payOutBid.amount = payOutBid.amount.sub(fragmentAmount);
        token = IERC20(payOutBid.tokenContract);
        highestBid[hNFTId] = payOutBid;
        token.transfer(msg.sender, fragmentAmount);

        emit PayOutIncreased(hNFTId, msg.sender, fragmentAmount);
    }

    function checkLarger(uint256 a, uint256 b) public pure returns(bool) {
        uint256 bPlusDiff = b.add(b.mul(2).div(10));
        return a >= bPlusDiff;
    }
}
