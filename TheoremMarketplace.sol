// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// Import Chainlink's DirectRequest Interface
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract TheoremMarketplace is ChainlinkClient, ConfirmedOwner, ReentrancyGuard {
    using Chainlink for Chainlink.Request;
    
    // Address of the Chainlink oracle (your node's address)
    address private oracle;

    // Job ID specific to your Chainlink job
    string private jobId;

    // LINK Token address on Sepolia
    address private constant LINK_TOKEN_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // Events
    event BountyDeclared(address sender, string theorem, uint256 value);
    event BountyRequested(address sender, string theorem);
    event BountyPaid(bytes32 requestID, address sender, string theorem, uint256 value);
    event BountyRequestDeclined(bytes32 requestID, address sender, string theorem);

    struct RequestData {
        address payable sender;
        string theorem;
    }

    mapping(string => uint256) public theoremBounties;
    mapping(bytes32 => RequestData) public requests;

    constructor(address _oracle, string memory _jobId) ConfirmedOwner(msg.sender) {
        _setChainlinkToken(LINK_TOKEN_ADDRESS);
        oracle = _oracle;
        jobId = _jobId;
    }

    /**
     * @notice Callback function for the Chainlink oracle to fulfill the request.
     * @param _requestId The ID of the Chainlink request.
     * @param _success The result of the proof verification.
     */
    function fulfill(bytes32 _requestId, bool _success) public nonReentrant recordChainlinkFulfillment(_requestId) {
        RequestData memory requestData = requests[_requestId];

        if (_success) {
            uint256 bountySize = theoremBounties[requestData.theorem];
            require(address(this).balance >= bountySize, "Verification successful but bounty exceeds balance");
            require(bountySize > 0, "Verification succeeded but no active bounty found");
            delete theoremBounties[requestData.theorem];
            (bool transactionSucceeded,) = requestData.sender.call{value: bountySize}("");
            require(transactionSucceeded, "Sending Ether failed");
            emit BountyPaid(_requestId, requestData.sender, requestData.theorem, bountySize);
        } else {
            emit BountyRequestDeclined(_requestId, requestData.sender, requestData.theorem);
        }
        delete requests[_requestId];
    }

    /**
     * @notice Allows the contract owner to withdraw LINK tokens.
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(LINK_TOKEN_ADDRESS);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function stringToBytes32(
        string memory source
    ) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    function declareBounty(string memory theorem) public payable {
        require(msg.value > 0, "Bounty must be greater than 0");

        // Update the bounty mapping
        theoremBounties[theorem] += msg.value;

        // Emit an event if desired
        emit BountyDeclared(msg.sender, theorem, msg.value);
    }

    function requestBounty(string memory theorem, string memory proof) public returns (bytes32 requestId) {
        require(theoremBounties[theorem] > 0, "There is no active bounty for this theorem");

        // Initialize a Chainlink request
        Chainlink.Request memory request = _buildChainlinkRequest(stringToBytes32(jobId), address(this), this.fulfill.selector);
        
        // Set CBOR-encoded parameters 
        request._add("theorem", theorem);
        request._add("proof", proof);

        // Send the request
        requestId = _sendChainlinkRequestTo(oracle, request, 0.1 * 10 ** 18);
        requests[requestId] = RequestData(payable(msg.sender), theorem); 
        emit BountyRequested(msg.sender, theorem);
    }
}
