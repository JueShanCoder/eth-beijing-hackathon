const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Auction", function () {
    let hnft;
    let ad3;
    let auction;
    let owner;
    let user;

    beforeEach(async () => {
        [owner, user] = await ethers.getSigners();

        const Auction = await ethers.getContractFactory("AuctionAndMicroPayment");
        auction = await Auction.deploy();
        await auction.deployed();

        const HNFT = await ethers.getContractFactory("ERC5489");
        hnft = await HNFT.deploy();
        await hnft.deployed();

        const AD3 = await ethers.getContractFactory("AD3Token");
        ad3 = await AD3.deploy(1000);
        await ad3.deployed();

        ad3.transfer(user.address, 200);
    });

    it("Should bid success", async () => {
        console.log(`[ad3] owner balance is ${await ad3.balanceOf(owner.address)}`);
        console.log(`[ad3] user  balance is ${await ad3.balanceOf(user.address)}`);

        // mint hnft.
        hnft.mint("http://xxxx");

        // approve to auction.
        hnft.approve(auction.address, 1);

        // first bid.
        await auction.bid(1, hnft.address, ad3.address, 100, "https://xxxxxx", { from: user.address });
        
    });

});