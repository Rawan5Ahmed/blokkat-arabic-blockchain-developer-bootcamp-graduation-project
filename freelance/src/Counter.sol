// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Freelance Escrow Contract
/// @author [Your Name]
/// @notice This contract manages escrow payments between clients and freelancers.
/// @dev Funds are stored in the contract and released upon job completion or refund.
contract FreelanceEscrow {
    /// @notice Possible statuses a job can have.
    enum JobStatus {
        Open,
        InProgress,
        Completed,
        Refunded
    }

    /// @notice Represents a freelance job.
    /// @param client The address of the client who posted the job.
    /// @param freelancer The address of the freelancer assigned to the job.
    /// @param amount The escrowed payment amount in wei.
    /// @param status The current status of the job.
    struct Job {
        address client;
        address freelancer;
        uint256 amount;
        JobStatus status;
    }

    /// @notice Counter tracking the total number of jobs created.
    uint256 public jobCounter;

    /// @notice Mapping from job ID to job details.
    mapping(uint256 => Job) public jobs;

    /// @notice Emitted when a new job is posted.
    /// @param jobId The unique ID of the job.
    /// @param client The address of the client.
    /// @param amount The escrowed amount in wei.
    event JobPosted(uint256 indexed jobId, address indexed client, uint256 amount);

    /// @notice Emitted when a freelancer applies and is assigned.
    /// @param jobId The job ID.
    /// @param freelancer The address of the freelancer.
    event FreelancerAssigned(uint256 indexed jobId, address indexed freelancer);

    /// @notice Emitted when a job is marked completed.
    /// @param jobId The job ID.
    event JobCompleted(uint256 indexed jobId);

    /// @notice Emitted when a job is refunded.
    /// @param jobId The job ID.
    event JobRefunded(uint256 indexed jobId);

    /// @notice Posts a new job with escrowed ETH.
    /// @dev The caller becomes the client, and must send ETH.
    /// @return The unique ID of the created job.
    function postJob() external payable returns (uint256) {
        require(msg.value > 0, "Must send ETH");

        jobCounter++;
        jobs[jobCounter] = Job({
            client: msg.sender,
            freelancer: address(0),
            amount: msg.value,
            status: JobStatus.Open
        });

        emit JobPosted(jobCounter, msg.sender, msg.value);
        return jobCounter;
    }

    /// @notice Assigns the caller as the freelancer for a job.
    /// @param jobId The ID of the job to apply for.
    function applyForJob(uint256 jobId) external {
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.Open, "Job not open");
        require(job.freelancer == address(0), "Already assigned");

        job.freelancer = msg.sender;
        job.status = JobStatus.InProgress;

        emit FreelancerAssigned(jobId, msg.sender);
    }

    /// @notice Marks a job as completed and releases funds to the freelancer.
    /// @param jobId The ID of the job to complete.
    function completeJob(uint256 jobId) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client can complete");
        require(job.status == JobStatus.InProgress, "Job not in progress");

        job.status = JobStatus.Completed;
        payable(job.freelancer).transfer(job.amount);

        emit JobCompleted(jobId);
    }

    /// @notice Refunds the escrowed payment back to the client.
    /// @param jobId The ID of the job to refund.
    function refundJob(uint256 jobId) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client can refund");
        require(
            job.status == JobStatus.Open || job.status == JobStatus.InProgress,
            "Cannot refund"
        );

        job.status = JobStatus.Refunded;
        payable(job.client).transfer(job.amount);

        emit JobRefunded(jobId);
    }
}
