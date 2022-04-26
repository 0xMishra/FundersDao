//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FundersDao is ReentrancyGuard, AccessControl {
  bytes32 public constant MEMBER = keccak256("MEMBER");
  bytes32 public constant STAKEHOLDER = keccak256("STAKEHOLDER");
  uint256 constant votingPeriod = 3 days;
  uint256 public proposalCount = 0;

  struct Funding {
    address payer;
    uint256 amount;
    uint256 timestamp;
  }

  struct Proposal {
    uint256 id;
    uint256 amount;
    uint256 livePeriod;
    uint256 voteInFavor;
    uint256 voteAgainst;
    string title;
    string desc;
    bool isCompleted;
    bool isPaid;
    address payable receiverAddress;
    address proposer;
    uint256 totalFundRaised;
    Funding[] funders;
  }

  mapping(uint256 => Proposal) private proposals;
  mapping(address => uint256) private stakeholders;
  mapping(address => uint256) private members;
  mapping(address => uint256[]) private votes;

  modifier onlyMembers(string memory message) {
    require(hasRole(MEMBER, msg.sender), message);
    _;
  }

  modifier onlyStakeholders(string memory message) {
    require(hasRole(STAKEHOLDER, msg.sender), message);
    _;
  }

  event newProposal(address proposer, uint256 amount);

  function createProposal(
    string calldata title,
    string calldata desc,
    address receiverAddress,
    uint256 amount
  ) public payable onlyMembers("Only Members can create proposals") {
    require(
      msg.value == 5 * 10**18,
      "you need to add 5 MATIC to create a proposal"
    );
    uint256 proposalId = proposalCount;
    Proposal storage proposal = proposals[proposalId];
    proposal.id = proposalId;
    proposal.title = title;
    proposal.desc = desc;
    proposal.amount = amount;
    proposal.receiverAddress = payable(receiverAddress);
    proposal.proposer = payable(msg.sender);
    proposal.livePeriod = block.timestamp + votingPeriod;
    proposal.isCompleted = false;
    proposal.isPaid = false;
    proposalCount++;
    emit newProposal(msg.sender, amount);
  }

  function getAllProposals() public view returns (Proposal[] memory) {
    Proposal[] memory allProposals = new Proposal[](proposalCount);
    for (uint256 i = 0; i < proposalCount; i++) {
      allProposals[i] = proposals[i];
    }
    return allProposals;
  }

  function getProposal(uint256 proposalId)
    public
    view
    returns (Proposal memory)
  {
    return proposals[proposalId];
  }

  function getVotes()
    public
    view
    onlyStakeholders("Only stakeholders can see the votes")
    returns (uint256[] memory)
  {
    return votes[msg.sender];
  }
}
