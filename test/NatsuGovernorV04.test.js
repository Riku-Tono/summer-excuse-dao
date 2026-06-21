const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NatsuDAO V04 - 夏の言い訳ガバナンス", function () {
  let natsu, genesis, oracle, governor;
  let owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    const Natsu = await ethers.getContractFactory("MockNatsuToken");
    natsu = await Natsu.deploy();
    await natsu.mint(owner.address, ethers.parseEther("10000"));

    const Genesis = await ethers.getContractFactory("MockGenesisNFT");
    genesis = await Genesis.deploy();
    await genesis.setBalance(owner.address, 10);
    await genesis.setSummerRoot(owner.address, true);

    const Oracle = await ethers.getContractFactory("MockHeatOracle");
    oracle = await Oracle.deploy();
    await oracle.setCicadaLevel(95);

    const Governor = await ethers.getContractFactory("SummerGovernorV04");
    governor = await Governor.deploy(await genesis.getAddress(), await natsu.getAddress(), await oracle.getAddress());
  });

  it("1クリックで言い訳がガバナンス資産になる", async function () {
    const excuse = "寝坊した…時計が夏の暑さで溶けた";

    await governor.createExcuseProposal(excuse, ethers.parseEther("0.5"));

    const events = await governor.queryFilter(governor.filters.ProposalCreated());
    const proposalId = events[events.length - 1].args.id;

    // ExcuseRecordedも出てる
    const excuseEvents = await governor.queryFilter(governor.filters.ExcuseRecorded());
    expect(excuseEvents.length).to.equal(1);

    await governor.vote(proposalId, true);
    await governor.cicadaOverride(proposalId);

    await ethers.provider.send("evm_increaseTime", [8 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine");

    await governor.execute(proposalId);

    const proposal = await governor.proposals(proposalId);
    expect(proposal.executed).to.equal(true);
    expect(proposal.probablySummer).to.equal(true);
  });
});