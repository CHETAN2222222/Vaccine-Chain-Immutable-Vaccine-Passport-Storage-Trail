// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Project - Vaccine Chain: Immutable Vaccine Passport & Storage Trail
 * @dev Smart contract for managing immutable vaccine records and verification
 * @author Vaccine Chain Team
 */
contract Project {
    
    // Struct to store vaccine record information
    struct VaccineRecord {
        uint256 recordId;
        address patientAddress;
        string patientName;
        string vaccineName;
        string manufacturer;
        string batchNumber;
        uint256 vaccinationDate;
        address healthcareProvider;
        string location;
        bool isVerified;
        uint256 timestamp;
    }
    
    // Struct for healthcare provider information
    struct HealthcareProvider {
        address providerAddress;
        string providerName;
        string licenseNumber;
        bool isApproved;
        uint256 registrationDate;
    }
    
    // State variables
    address public owner;
    uint256 private recordCounter;
    
    // Mappings
    mapping(uint256 => VaccineRecord) public vaccineRecords;
    mapping(address => uint256[]) public patientRecords;
    mapping(address => HealthcareProvider) public healthcareProviders;
    mapping(string => bool) public usedBatchNumbers;
    
    // Events
    event VaccineRecorded(
        uint256 indexed recordId,
        address indexed patient,
        string vaccineName,
        address indexed provider,
        uint256 timestamp
    );
    
    event ProviderRegistered(
        address indexed provider,
        string providerName,
        uint256 timestamp
    );
    
    event RecordVerified(
        uint256 indexed recordId,
        address indexed verifier,
        bool status,
        uint256 timestamp
    );
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyApprovedProvider() {
        require(
            healthcareProviders[msg.sender].isApproved,
            "Only approved healthcare providers can record vaccines"
        );
        _;
    }
    
    modifier validRecordId(uint256 _recordId) {
        require(_recordId > 0 && _recordId <= recordCounter, "Invalid record ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        recordCounter = 0;
    }
    
    /**
     * @dev Core Function 1: Register Healthcare Provider
     * @param _providerName Name of the healthcare provider
     * @param _licenseNumber Medical license number of the provider
     */
    function registerProvider(
        string memory _providerName,
        string memory _licenseNumber
    ) external {
        require(bytes(_providerName).length > 0, "Provider name cannot be empty");
        require(bytes(_licenseNumber).length > 0, "License number cannot be empty");
        require(
            healthcareProviders[msg.sender].providerAddress == address(0),
            "Provider already registered"
        );
        
        healthcareProviders[msg.sender] = HealthcareProvider({
            providerAddress: msg.sender,
            providerName: _providerName,
            licenseNumber: _licenseNumber,
            isApproved: false,
            registrationDate: block.timestamp
        });
        
        emit ProviderRegistered(msg.sender, _providerName, block.timestamp);
    }
    
    /**
     * @dev Core Function 2: Record Vaccine Administration
     * @param _patientAddress Address of the patient receiving the vaccine
     * @param _patientName Name of the patient
     * @param _vaccineName Name of the administered vaccine
     * @param _manufacturer Manufacturer of the vaccine
     * @param _batchNumber Batch number of the vaccine
     * @param _location Location where vaccine was administered
     */
    function recordVaccination(
        address _patientAddress,
        string memory _patientName,
        string memory _vaccineName,
        string memory _manufacturer,
        string memory _batchNumber,
        string memory _location
    ) external onlyApprovedProvider {
        require(_patientAddress != address(0), "Invalid patient address");
        require(bytes(_patientName).length > 0, "Patient name cannot be empty");
        require(bytes(_vaccineName).length > 0, "Vaccine name cannot be empty");
        require(bytes(_batchNumber).length > 0, "Batch number cannot be empty");
        
        recordCounter++;
        uint256 newRecordId = recordCounter;
        
        VaccineRecord memory newRecord = VaccineRecord({
            recordId: newRecordId,
            patientAddress: _patientAddress,
            patientName: _patientName,
            vaccineName: _vaccineName,
            manufacturer: _manufacturer,
            batchNumber: _batchNumber,
            vaccinationDate: block.timestamp,
            healthcareProvider: msg.sender,
            location: _location,
            isVerified: true,
            timestamp: block.timestamp
        });
        
        vaccineRecords[newRecordId] = newRecord;
        patientRecords[_patientAddress].push(newRecordId);
        usedBatchNumbers[_batchNumber] = true;
        
        emit VaccineRecorded(
            newRecordId,
            _patientAddress,
            _vaccineName,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @dev Core Function 3: Verify Vaccine Record
     * @param _recordId ID of the vaccine record to verify
     * @return VaccineRecord The complete vaccine record information
     */
    function verifyVaccineRecord(uint256 _recordId)
        external
        view
        validRecordId(_recordId)
        returns (VaccineRecord memory)
    {
        VaccineRecord memory record = vaccineRecords[_recordId];
        require(record.isVerified, "Record is not verified");
        
        return record;
    }
    
    // Additional utility functions
    
    /**
     * @dev Approve healthcare provider (only owner)
     * @param _providerAddress Address of the provider to approve
     */
    function approveProvider(address _providerAddress) external onlyOwner {
        require(
            healthcareProviders[_providerAddress].providerAddress != address(0),
            "Provider not registered"
        );
        
        healthcareProviders[_providerAddress].isApproved = true;
    }
    
    /**
     * @dev Get all vaccine records for a specific patient
     * @param _patientAddress Address of the patient
     * @return uint256[] Array of record IDs for the patient
     */
    function getPatientVaccineRecords(address _patientAddress)
        external
        view
        returns (uint256[] memory)
    {
        return patientRecords[_patientAddress];
    }
    
    /**
     * @dev Check if a batch number has been used
     * @param _batchNumber Batch number to check
     * @return bool True if batch number has been used
     */
    function isBatchNumberUsed(string memory _batchNumber)
        external
        view
        returns (bool)
    {
        return usedBatchNumbers[_batchNumber];
    }
    
    /**
     * @dev Get total number of vaccine records
     * @return uint256 Total number of records created
     */
    function getTotalRecords() external view returns (uint256) {
        return recordCounter;
    }
    
    /**
     * @dev Update record verification status (only owner)
     * @param _recordId ID of the record to update
     * @param _status New verification status
     */
    function updateRecordVerification(uint256 _recordId, bool _status)
        external
        onlyOwner
        validRecordId(_recordId)
    {
        vaccineRecords[_recordId].isVerified = _status;
        
        emit RecordVerified(_recordId, msg.sender, _status, block.timestamp);
    }
}
