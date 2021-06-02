const hre = require("hardhat");

async function main() {
  const Ballot = await hre.ethers.getContractFactory("Ballot");
  const ballot = await Ballot.deploy();
  const Proxy = await hre.ethers.getContractFactory("TransparentProxy");
  const proxy = await Proxy.deploy(ballot.address);

  //In prod, we'd want to deploy and init in one TX
  await ballot.deployed();
  await proxy.deployed();

  console.log("Ballot deployed to:", ballot.address);
  console.log("Proxy deployed to:", proxy.address);

  const ballotProxy = await Ballot.attach(proxy.address);
  //await ballotProxy.initialize(3);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
