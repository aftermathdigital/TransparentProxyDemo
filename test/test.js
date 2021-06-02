const { expect } = require("chai");

describe("TransparentProxy", function() {

  beforeEach(async function () {
    //In prod, we'd want to deploy and init in one TX
    const Ballot = await hre.ethers.getContractFactory("Ballot");
    const ballot = await Ballot.deploy();
    const Proxy = await hre.ethers.getContractFactory("TransparentProxy");
    const proxy = await Proxy.deploy(ballot.address);
  
    await ballot.deployed();
    await proxy.deployed();
      
    ballotProxy = await Ballot.attach(proxy.address);
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
  });

  describe("Initialize", function() {
    it("Should be initializable", async function() {
      await ballotProxy.initialize(3);
    });
  });
  
  describe("Registration", function() {
    it("Should allow the chairperson to register new voters", async function() {
      await ballotProxy.initialize(3);
      await ballotProxy.register(addr1.address);
      await ballotProxy.register(addr2.address);
    });
  });

  describe("Voting", function() {
    it("Should allow registered voters to vote", async function() {
      await ballotProxy.initialize(3);
      await ballotProxy.register(addr1.address);
      await ballotProxy.register(addr2.address);
      await ethers.provider.send("evm_increaseTime", [31]);
      await ethers.provider.send("evm_mine");
      await ballotProxy.vote(0);
      await ballotProxy.connect(addr1).vote(1);
      await ballotProxy.connect(addr2).vote(2);
      //addr3 was never registered
      expect(await ballotProxy.connect(addr3).vote(2)).to.be.reverted;
    });
  });

  describe("Ballot Counting", function() {
    it("Should count correctly", async function() {
      await ballotProxy.initialize(3);
      await ballotProxy.register(addr1.address);
      await network.provider.send("evm_increaseTime", [31]);
      await network.provider.send("evm_mine");
      await ballotProxy.vote(0);
      await ballotProxy.connect(addr1).vote(1);
      await network.provider.send("evm_increaseTime", [31]);
      await network.provider.send("evm_mine");
      expect(ballotProxy.winningProposal()).to.equal(0);
    });
  });
});