import { describe, it, beforeEach } from "node:test";
import assert from "node:assert";

describe("PakistanVotingSystem", { concurrency: false }, () => {
  let votingSystem;
  let admin, voter1, voter2;

  beforeEach(async () => {
    const hre = await import("hardhat");
    const signers = await hre.ethers.getSigners();
    [admin, voter1, voter2] = signers;
    
    const PakistanVotingSystem = await hre.ethers.getContractFactory("PakistanVotingSystem");
    votingSystem = await PakistanVotingSystem.deploy();
  });

  it("should set the right admin", async () => {
    const contractAdmin = await votingSystem.admin();
    assert.strictEqual(contractAdmin, admin.address);
  });

  it("should add candidate", async () => {
    await votingSystem.addCandidate("Imran Khan", "Bat");
    const candidates = await votingSystem.getAllCandidates();
    
    assert.strictEqual(candidates[0].name, "Imran Khan");
    assert.strictEqual(candidates[0].partySymbol, "Bat");
    assert.strictEqual(candidates[0].voteCount, 0n);
  });

  it("should register voter", async () => {
    await votingSystem.registerVoter(voter1.address);
    const voterStatus = await votingSystem.getVoterStatus(voter1.address);
    
    assert.strictEqual(voterStatus[0], true); // isRegistered
    assert.strictEqual(voterStatus[1], false); // hasVoted
    assert.strictEqual(voterStatus[2], 1n); // weight
  });

  it("should allow voting", async () => {
    // Setup
    await votingSystem.addCandidate("Test Candidate", "Symbol");
    await votingSystem.registerVoter(voter1.address);
    
    // Set voting period (start now, end in 1 hour)
    const startTime = Math.floor(Date.now() / 1000);
    const endTime = startTime + 3600;
    await votingSystem.initializeVotingPeriod(startTime, endTime);
    
    // Vote
    await votingSystem.connect(voter1).vote(0);
    
    // Check results
    const candidates = await votingSystem.getAllCandidates();
    const voterStatus = await votingSystem.getVoterStatus(voter1.address);
    
    assert.strictEqual(candidates[0].voteCount, 1n);
    assert.strictEqual(voterStatus[1], true); // hasVoted
  });

  it("should prevent double voting", async () => {
    await votingSystem.addCandidate("Test Candidate", "Symbol");
    await votingSystem.registerVoter(voter1.address);
    
    const startTime = Math.floor(Date.now() / 1000);
    const endTime = startTime + 3600;
    await votingSystem.initializeVotingPeriod(startTime, endTime);
    
    await votingSystem.connect(voter1).vote(0);
    
    // Try to vote again
    await assert.rejects(
      votingSystem.connect(voter1).vote(0),
      { message: "You have already voted" }
    );
  });
});