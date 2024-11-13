pragma solidity ^0.8.13;

contract EduEna {

    struct Donor {
        string name;
        uint256 amountDonated;
    }

    struct Recipient {
        string name;
        uint256 fundsAllocated;
        bool hasReceivedFunds;
    }

    address public ngo;
    uint256 public totalFunds;

    mapping(address => Donor) public donors;
    mapping(address => Recipient) public recipients;

    // Events
    event DonationReceived(address indexed donor, uint256 amount);
    event FundsAllocated(address indexed recipient, uint256 amount);
    event FundsDisbursed(address indexed recipient, uint256 amount);

    modifier onlyNGO() {
        require(msg.sender == ngo, "Only the NGO can call this function");
        _;
    }

    constructor() {
        ngo = msg.sender;
    }

    function donate(string memory donorName) public payable {
        require(msg.value > 0, "Donation amount must be greater than 0");

        Donor storage donor = donors[msg.sender];
        donor.name = donorName;
        donor.amountDonated += msg.value;

        totalFunds += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    function allocationFunds(address recipientAddress, string memory recipientName, uint256 amount) public onlyNGO {
        require(totalFunds >= amount, "Insufficient funds");

        Recipient storage recipient = recipients[recipientAddress];
        recipient.name = recipientName;
        recipient.fundsAllocated += amount;
        recipient.hasReceivedFunds = false;

        totalFunds -= amount;
        emit FundsAllocated(recipientAddress, amount);
    }

    function disburseFunds(address recipientAddress) external onlyNGO {
        Recipient storage recipient = recipients[recipientAddress];
        require(recipient.fundsAllocated > 0, "No funds allocated to this recipient");
        require(!recipient.hasReceivedFunds, "Funds already disbursed to this recipient");

        recipient.hasReceivedFunds = true;
        payable(recipientAddress).transfer(recipient.fundsAllocated);
        emit FundsDisbursed(recipientAddress, recipient.fundsAllocated);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

}