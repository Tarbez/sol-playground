pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

struct Proposal {
    address proposer;
    string title;
    string description;
    string[] useCases;
    string[] comments;
    address[] commenters;
    bool executed;
    uint256 potentialImpact;
    uint256 potentialRewards;
    address[] accessControl;
    uint256 proposalId;
    mapping(address => bool) voted;
    uint256 voteCount;
}

contract CUDDAOCommunications is AccessControl {
    uint256 public proposalCount;
    address public nftCollectionAddress = 0x123456789abcdef01234567890abcdef;
    address public owner;
    address public tokenAddress;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public commenter;
    
    AccessControl public accessControl;
    event ProposalExecuted(uint256 proposalId);
    event CommentAdded(uint256 proposalId, address sender, string comment);

    constructor() public {
        owner = msg.sender;
        accessControl = new AccessControl();
        accessControl.createRole("proposer", msg.sender);
        accessControl.createRole("commenter", msg.sender);
        proposalCount++;
    }

    function isTokenHolder(address _address) public view returns (bool) {
        return IERC20(tokenAddress).balanceOf(_address) > 0;
    }

    function isValidNFT(address _tokenAddress) public view returns (bool) {
        return _tokenAddress == nftCollectionAddress;
    }

    function requireValidNFT() internal {
        require(isValidNFT(tokenAddress));
    }

    function requireTokenHolder() internal {
        require(isTokenHolder(msg.sender));
    }

  function addProposal(
    address _tokenAddress,
    string memory _title,
    string memory _description,
    string[] memory _useCases,
    uint256 _potentialImpact,
    uint256 _potentialRewards,
    address[] memory _accessControl
) public {
    require(_tokenAddress != address(0));
    requireValidNFT();
    requireTokenHolder();
    require(accessControl.isRoleMember("proposer", msg.sender));
    Proposal memory newProposal = Proposal({
        proposer: msg.sender,
        title: _title,
        description: _description,
        useCases: _useCases,
        executed: false,
        potentialImpact: _potentialImpact,
        potentialRewards: _potentialRewards,
        accessControl: _accessControl,
        proposalId: proposalCount + 1,
        voted: new mapping(address => bool),
        voteCount: 0,
        comments: new string[](0),
        commenters: new address[](0)
    });
    proposals[proposalCount + 1] = newProposal;
    proposalCount++;
}

function executeProposal(uint256 _proposalId) public onlyRole(msg.sender, "proposer") {
    require(_proposalId > 0 && _proposalId <= proposalCount);
    Proposal storage proposal = proposals[_proposalId];

    // Check if proposal has been voted on
    require(proposal.voteCount > 0);

    // Check if proposal has been executed
    require(!proposal.executed);

    // Execute proposal
    proposal.executed = true;

    // Add voter role to all voters
    for (address voter in proposal.voted) {
        accessControl.createRole("voter", voter);
    }

    // Add commenter role to all commenters
    for (address commenter in proposal.commenters) {
        accessControl.createRole("commenter", commenter);
    }

        // Emit event
        emit ProposalExecuted(_proposalId);
    }

    function getCommenter(Proposal storage proposal, string memory comment)
        private
        view
        returns (address)
    {
        for (uint256 i = 0; i < proposal.comments.length; i++) {
            if (proposal.comments[i] == comment) {
                return proposal.commenters[i];
            }
        }
        return address(0);
    }

    function vote(uint256 _proposalId) public {
        require(isTokenHolder(msg.sender));
        require(accessControl.isRoleMember("voter", msg.sender));
        require(_proposalId > 0 && _proposalId <= proposalCount);
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.voted[msg.sender]);
        proposal.voted[msg.sender] = true;
        proposal.voteCount++;
        emit VoteAdded(_proposalId, msg.sender);
    }

    event VoteAdded(uint256 proposalId, address sender);

    function vote(uint256 _proposalId) public {
        require(isTokenHolder(msg.sender));
        require(accessControl.isRoleMember("voter", msg.sender));
        require(_proposalId > 0 && _proposalId <= proposalCount);
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.voted[msg.sender]);
        proposal.voted[msg.sender] = true;
        proposal.voteCount++;
        emit VoteAdded(_proposalId, msg.sender);
    }

    function addComment(uint256 _proposalId, string memory _comment) public {
        require(_proposalId > 0 && _proposalId <= proposalCount);
        require(accessControl.isRoleMember("commenter", msg.sender));
        Proposal storage proposal = proposals[_proposalId];
        proposal.comments.push(_comment);
        proposal.commenters.push(msg.sender);
        emit CommentAdded(_proposalId, msg.sender, _comment);
        address commenter = getCommenter(proposal, comment);
    }
}
