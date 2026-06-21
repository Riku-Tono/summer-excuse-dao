// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface INatsuToken {
    function burnFrom(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IGenesisNFT {
    function balanceOf(address owner) external view returns (uint256);
    function hasSleepCycleBug(address owner) external view returns (bool);
    function hasLegendaryTripBug(address owner) external view returns (bool);
    function hasWalletBug(address owner) external view returns (bool);
    function hasSummerRoot(address owner) external view returns (bool);
}

interface IHeatOracle {
    function currentTemperature() external view returns (uint256);
    function cicadaLevel() external view returns (uint256);
}

contract SummerGovernorV04 {
    enum ProposalType { SummerExtension, BugForgiveness, NewBugMint, TreasurySpend, CourtAppeal }

    struct Proposal {
        address proposer;
        ProposalType proposalType;
        string title;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
        bool executed;
        bool summerBiased;
        bool probablySummer;
        bool vetoedBySummerCourt;
        address target;
        uint256 value;
        bytes executionPayload;
    }

    IGenesisNFT public genesis;
    INatsuToken public natsu;
    IHeatOracle public heatOracle;

    uint256 public proposalCount;
    uint256 public constant PROPOSAL_BURN = 1 ether;
    uint256 public constant MIN_EXCUSE_BURN = 0.1 ether;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => bool)) public usedEternalDelay;

    event ProposalCreated(uint256 indexed id, string title, ProposalType proposalType);
    event ExcuseRecorded(uint256 indexed proposalId, address indexed user, string excuse, uint256 natsuAmount);
    event Voted(uint256 indexed id, address voter, bool support, uint256 power);
    event Executed(uint256 indexed id, bool passed);
    event EternalDelayUsed(uint256 indexed id, address user);
    event HeatExtended(uint256 indexed id, uint256 temperature);
    event CicadaOverride(uint256 indexed id, uint256 cicadaLevel);
    event SummerCourtVeto(uint256 indexed id, address judge);

    constructor(address genesisNFT, address natsuToken, address heatOracle_) {
        genesis = IGenesisNFT(genesisNFT);
        natsu = INatsuToken(natsuToken);
        heatOracle = IHeatOracle(heatOracle_);
    }

    modifier isProbablySummer(uint256 id) {
        Proposal storage p = proposals[id];
        if (p.summerBiased) p.probablySummer = true;
        _;
    }

    function votingPower(address user, ProposalType proposalType) public view returns (uint256) {
        uint256 power = genesis.balanceOf(user);
        if (proposalType == ProposalType.SummerExtension && genesis.hasLegendaryTripBug(user)) power += 3;
        if (proposalType == ProposalType.CourtAppeal && genesis.hasSleepCycleBug(user)) power += 2;
        if (proposalType == ProposalType.TreasurySpend && genesis.hasWalletBug(user)) power += 1;
        if (genesis.hasSummerRoot(user)) power += 5;
        return power;
    }

    function createProposal(
        ProposalType proposalType,
        string calldata title,
        bool summerBiased,
        address target,
        uint256 value,
        bytes calldata executionPayload
    ) external returns (uint256) {
        natsu.burnFrom(msg.sender, PROPOSAL_BURN);
        require(votingPower(msg.sender, proposalType) > 0, "not summer enough");

        proposalCount++;
        uint256 period = proposalType == ProposalType.SummerExtension ? 14 days : 7 days;

        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            proposalType: proposalType,
            title: title,
            yesVotes: 0,
            noVotes: 0,
            deadline: block.timestamp + period,
            executed: false,
            summerBiased: summerBiased,
            probablySummer: false,
            vetoedBySummerCourt: false,
            target: target,
            value: value,
            executionPayload: executionPayload
        });

        emit ProposalCreated(proposalCount, title, proposalType);
        return proposalCount;
    }

    function createExcuseProposal(string calldata excuse, uint256 burnAmount) external returns (uint256) {
        require(burnAmount >= MIN_EXCUSE_BURN, "excuse too cheap");
        require(votingPower(msg.sender, ProposalType.BugForgiveness) > 0, "not summer enough");

        natsu.burnFrom(msg.sender, burnAmount);

        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            proposalType: ProposalType.BugForgiveness,
            title: string.concat("Excuse: ", excuse),
            yesVotes: 0,
            noVotes: 0,
            deadline: block.timestamp + 7 days,
            executed: false,
            summerBiased: true,
            probablySummer: false,
            vetoedBySummerCourt: false,
            target: address(0),
            value: 0,
            executionPayload: ""
        });

        if (heatOracle.cicadaLevel() >= 70) {
            proposals[proposalCount].probablySummer = true;
        }

        emit ProposalCreated(proposalCount, proposals[proposalCount].title, ProposalType.BugForgiveness);
        emit ExcuseRecorded(proposalCount, msg.sender, excuse, burnAmount);
        return proposalCount;
    }

    function vote(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        require(block.timestamp < p.deadline, "summer already ended");
        require(!hasVoted[id][msg.sender], "already shouted");
        require(!p.vetoedBySummerCourt, "vetoed by summer court");

        uint256 power = votingPower(msg.sender, p.proposalType);
        require(power > 0, "no summer rights");

        if (support && p.summerBiased) power = power * 120 / 100;

        if (support) p.yesVotes += power;
        else p.noVotes += power;

        hasVoted[id][msg.sender] = true;
        emit Voted(id, msg.sender, support, power);
    }

    function cicadaOverride(uint256 id) external {
        Proposal storage p = proposals[id];
        uint256 level = heatOracle.cicadaLevel();
        require(level >= 70, "not enough cicada");  // 言い訳用に少し緩く

        p.probablySummer = true;
        p.yesVotes = p.yesVotes * 130 / 100;
        emit CicadaOverride(id, level);
    }

    function execute(uint256 id) external isProbablySummer(id) {
        Proposal storage p = proposals[id];
        require(block.timestamp >= p.deadline, "still summer");
        require(!p.executed, "already executed");
        require(!p.vetoedBySummerCourt, "vetoed");

        bool passed = p.yesVotes > p.noVotes || (p.probablySummer && p.yesVotes >= p.noVotes);
        p.executed = true;

        emit Executed(id, passed);
    }

    // 他の関数（autoExtendIfHot, useEternalDelay, summerCourtVeto）は必要なら追加可能
    receive() external payable {}
}