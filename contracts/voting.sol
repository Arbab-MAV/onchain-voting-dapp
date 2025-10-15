
/*
======ETHOnline 2025 Hackathon by ETH Global====== 

  Project: Blokchain based Voting system
  Author: MAV aka Muhammad Abdullah Arbab
  File: voting.sol
  Description: A temper proof Blockchain based voting system for Pakistan
  Date: 15 October 2025
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PakistanVotingSystem {
    // ===== STRUCTS =====
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        string partySymbol; // Added for Pakistani context
    }
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint weight; // Could represent voting power (1 for normal voter)
    }

    // ===== STATE VARIABLES =====
    address public admin;
    
    // Track voters by their address
    mapping(address => Voter) public voters;
    
    // Array to store candidates
    Candidate[] public candidates;
    
    // Voting period timestamps
    uint public votingStartTime;
    uint public votingEndTime;
    
    // Track if voting has been initialized
    bool public votingInitialized;

    // ===== EVENTS =====
    event VoterRegistered(address voter);
    event CandidateAdded(uint candidateId, string name, string partySymbol);
    event VoteCast(address voter, uint candidateId);
    event VotingPeriodSet(uint startTime, uint endTime);

    // ===== MODIFIERS =====
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyDuringVotingPeriod() {
        require(block.timestamp >= votingStartTime && block.timestamp <= votingEndTime, "Voting period is not active");
        _;
    }
    
    modifier onlyAfterVoting() {
        require(block.timestamp > votingEndTime, "Voting period has not ended");
        _;
    }

    // ===== CONSTRUCTOR =====
    constructor() {
        admin = msg.sender;
        votingInitialized = false;
    }

    // ===== ADMIN FUNCTIONS =====
    
    /**
     * @dev Initialize voting period - can only be done once
     * @param _startTime Start timestamp of voting
     * @param _endTime End timestamp of voting
     */
    function initializeVotingPeriod(uint _startTime, uint _endTime) external onlyAdmin {
        require(!votingInitialized, "Voting already initialized");
        require(_startTime >= block.timestamp, "Start time must be in future");
        require(_endTime > _startTime, "End time must be after start time");
        
        votingStartTime = _startTime;
        votingEndTime = _endTime;
        votingInitialized = true;
        
        emit VotingPeriodSet(_startTime, _endTime);
    }
    
    /**
     * @dev Register a single voter
     * @param _voterAddress Address of the voter to register
     */
    function registerVoter(address _voterAddress) external onlyAdmin {
        require(!voters[_voterAddress].isRegistered, "Voter already registered");
        require(_voterAddress != address(0), "Invalid voter address");
        
        voters[_voterAddress] = Voter({
            isRegistered: true,
            hasVoted: false,
            weight: 1
        });
        
        emit VoterRegistered(_voterAddress);
    }
    
    /**
     * @dev Register multiple voters at once (gas efficient for hackathon)
     * @param _voterAddresses Array of voter addresses to register
     */
    function registerVotersInBatch(address[] calldata _voterAddresses) external onlyAdmin {
        for (uint i = 0; i < _voterAddresses.length; i++) {
            if (!voters[_voterAddresses[i]].isRegistered && _voterAddresses[i] != address(0)) {
                voters[_voterAddresses[i]] = Voter({
                    isRegistered: true,
                    hasVoted: false,
                    weight: 1
                });
                emit VoterRegistered(_voterAddresses[i]);
            }
        }
    }
    
    /**
     * @dev Add a new candidate to the election
     * @param _name Name of the candidate
     * @param _partySymbol Party symbol (e.g., "Boat", "Lion" etc.)
     */
    function addCandidate(string memory _name, string memory _partySymbol) external onlyAdmin {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        
        uint candidateId = candidates.length;
        candidates.push(Candidate({
            id: candidateId,
            name: _name,
            voteCount: 0,
            partySymbol: _partySymbol
        }));
        
        emit CandidateAdded(candidateId, _name, _partySymbol);
    }

    // ===== VOTER FUNCTIONS =====
    
    /**
     * @dev Cast a vote for a candidate
     * @param _candidateId ID of the candidate to vote for
     */
    function vote(uint _candidateId) external onlyDuringVotingPeriod {
        // Check if voter is registered
        require(voters[msg.sender].isRegistered, "You are not registered to vote");
        
        // Check if voter hasn't already voted
        require(!voters[msg.sender].hasVoted, "You have already voted");
        
        // Check if candidate exists
        require(_candidateId < candidates.length, "Invalid candidate ID");
        
        // Mark voter as having voted
        voters[msg.sender].hasVoted = true;
        
        // Add the vote to candidate
        candidates[_candidateId].voteCount += voters[msg.sender].weight;
        
        emit VoteCast(msg.sender, _candidateId);
    }

    // ===== VIEW FUNCTIONS =====
    
    /**
     * @dev Get total number of candidates
     */
    function getCandidatesCount() external view returns (uint) {
        return candidates.length;
    }
    
    /**
     * @dev Get all candidates with their details
     */
    function getAllCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }
    
    /**
     * @dev Get voting results (only after voting ends)
     */
    function getResults() external view onlyAfterVoting returns (Candidate[] memory) {
        return candidates;
    }
    
    /**
     * @dev Check if voting is currently active
     */
    function isVotingActive() external view returns (bool) {
        return (block.timestamp >= votingStartTime && block.timestamp <= votingEndTime);
    }
    
    /**
     * @dev Check voter status for a specific address
     */
    function getVoterStatus(address _voterAddress) external view returns (bool isRegistered, bool hasVoted, uint weight) {
        Voter memory voter = voters[_voterAddress];
        return (voter.isRegistered, voter.hasVoted, voter.weight);
    }
    
    /**
     * @dev Get total votes cast so far
     */
    function getTotalVotesCast() external view returns (uint totalVotes) {
        totalVotes = 0;
        for (uint i = 0; i < candidates.length; i++) {
            totalVotes += candidates[i].voteCount;
        }
    }
    
    /**
     * @dev Get time remaining for voting (useful for frontend)
     */
    function getTimeRemaining() external view returns (uint timeRemaining) {
        if (block.timestamp < votingStartTime) {
            return 0; // Voting hasn't started
        } else if (block.timestamp > votingEndTime) {
            return 0; // Voting ended
        } else {
            return votingEndTime - block.timestamp;
        }
    }
}