// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FreelanceEscrow.sol";

contract FreelanceEscrowTest is Test {
    FreelanceEscrow escrow;
    address client = address(1);
    address freelancer = address(2);

    function setUp() public {
        escrow = new FreelanceEscrow();
        vm.deal(client, 10 ether);
        vm.deal(freelancer, 10 ether);
    }

    function testPostJob() public {
        vm.prank(client);
        uint256 jobId = escrow.postJob{value: 1 ether}();
        (address _client,, uint256 amount,) = escrow.jobs(jobId);
        assertEq(_client, client);
        assertEq(amount, 1 ether);
    }

    function testApplyAndCompleteJob() public {
        vm.prank(client);
        uint256 jobId = escrow.postJob{value: 1 ether}();
        vm.prank(freelancer);
        escrow.applyForJob(jobId);
        vm.prank(client);
        escrow.completeJob(jobId);
    }

    function testRefundJob() public {
        vm.prank(client);
        uint256 jobId = escrow.postJob{value: 1 ether}();
        vm.prank(client);
        escrow.refundJob(jobId);
    }
}
