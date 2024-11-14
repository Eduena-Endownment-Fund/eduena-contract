// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ScholarshipManager {
    address public owner;
    uint256 public scholarshipCount;

    struct Scholarship {
        uint256 id;
        uint256 amount;
        string criteria;
        address[] applicants;
        mapping(address => bool) verifiedApplicants;
        mapping(address => bool) claimed;
    }

    mapping(uint256 => Scholarship) public scholarships;

    event ScholarshipCreated(uint256 indexed scholarshipId, uint256 amount, string criteria);
    event ScholarshipUpdated(uint256 indexed scholarshipId, uint256 amount, string criteria);
    event ScholarshipApplied(uint256 indexed scholarshipId, address indexed applicant);
    event ApplicantVerified(uint256 indexed scholarshipId, address indexed applicant);
    event ScholarshipClaimed(uint256 indexed scholarshipId, address indexed applicant);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createScholarship(uint256 amount, string memory criteria) external onlyOwner {
        scholarshipCount++;
        Scholarship storage scholarship = scholarships[scholarshipCount];
        scholarship.id = scholarshipCount;
        scholarship.amount = amount;
        scholarship.criteria = criteria;

        emit ScholarshipCreated(scholarshipCount, amount, criteria);
    }

    function updateScholarship(uint256 scholarshipId, uint256 amount, string memory criteria) external onlyOwner {
        Scholarship storage scholarship = scholarships[scholarshipId];
        scholarship.amount = amount;
        scholarship.criteria = criteria;

        emit ScholarshipUpdated(scholarshipId, amount, criteria);
    }

    function getScholarshipDetails(uint256 scholarshipId) external view returns (uint256, uint256, string memory, address[] memory) {
        Scholarship storage scholarship = scholarships[scholarshipId];
        return (scholarship.id, scholarship.amount, scholarship.criteria, scholarship.applicants);
    }

    function applyForScholarship(uint256 scholarshipId) external {
        Scholarship storage scholarship = scholarships[scholarshipId];
        scholarship.applicants.push(msg.sender);

        emit ScholarshipApplied(scholarshipId, msg.sender);
    }

    function verifyApplicant(address applicant, uint256 scholarshipId) external onlyOwner {
        Scholarship storage scholarship = scholarships[scholarshipId];
        scholarship.verifiedApplicants[applicant] = true;

        emit ApplicantVerified(scholarshipId, applicant);
    }

    function getApplicantStatus(address applicant, uint256 scholarshipId) external view returns (bool) {
        Scholarship storage scholarship = scholarships[scholarshipId];
        return scholarship.verifiedApplicants[applicant];
    }

    function claimScholarship(uint256 scholarshipId) external {
        Scholarship storage scholarship = scholarships[scholarshipId];
        require(scholarship.verifiedApplicants[msg.sender], "Applicant not verified");
        require(!scholarship.claimed[msg.sender], "Scholarship already claimed");

        scholarship.claimed[msg.sender] = true;

        emit ScholarshipClaimed(scholarshipId, msg.sender);
    }
}