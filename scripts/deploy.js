async function main() {
  console.log("Deploy Auction contract...");
  const Auction = await ethers.getContractFactory("AuctionAndMicroPayment");
  const auction = await Auction.deploy();
  await auction.deployed();

  console.log("Deploy ERC5489 contract...");
  const HNFT = await ethers.getContractFactory("ERC5489");
  const hnft = await HNFT.deploy();
  await hnft.deployed();

  console.log("Deploy AD3Token contract...");
  const AD3 = await ethers.getContractFactory("AD3Token");
  const ad3 = await AD3.deploy(1000);
  await ad3.deployed();

  console.log("auction address is: ", auction.address);
  console.log("erc5489 address is: ", hnft.address);
  console.log("ad3Token address is: ", ad3.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});