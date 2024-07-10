    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: WPV.sol



pragma solidity ^0.8.0;


//**** Interfaces ****//

    interface IRegistration{
        enum EntityType{Unregistered, RegulatoryAuthority, Oracle, Factory}
        function getEntity(address) external returns(EntityType, bool);
    }

contract WPV is ReentrancyGuard{

    //**** State Variable ****//

    IRegistration public Registration;
    uint256 public reportCount; //This counter is used for tracking purposes

    struct ViolationReport{
        address oracle; //The address of the reporting oracle
        uint256 reportingTime; //This is equivalant to timestamp, to get the accurate violation time, use the time included the report hash
        bytes32 violationReportHash; //This is the IPFS hash of the submitted report
        bool isVerified; //This boolean is set to true if the regulatory authority validates the submitted violation report
    }

    //Report ID => Report Details (This mapping assigns a unique ID for each submitted report)
    mapping(uint256 => ViolationReport) public violationReports;

    //**** Constructor ****//
    constructor(address _registration){
        Registration = IRegistration(_registration);
        //reportCount = 0;
    }

        //**** Modifiers ****//
    modifier onlyRegulatoryAuthority{
        (IRegistration.EntityType entitytype, bool isRegistered) = Registration.getEntity(msg.sender);
        require(entitytype == IRegistration.EntityType.RegulatoryAuthority && isRegistered, "Only the regulatory authority can run this function");
        _;
    }

    modifier onlyOracle{
        (IRegistration.EntityType entitytype, bool isRegistered) = Registration.getEntity(msg.sender);
        require(entitytype == IRegistration.EntityType.Oracle && isRegistered, "Only the Reporting Oracle can run this function");
        _;
    }


    //**** Events ****//
    event NewViolationReportSubmission(uint256 indexed reportCount,address reporter, uint256 date, bytes32 reportDetails);
    event ViolationReportVerification(uint256 indexed reportCount, address inspector, bool isVerified, uint256 verificationDate);
    event ReportVerified(address regulatoryAuthority, uint256 reportiD, uint256 date);
    event ReportRejected(address regulatoryAuthority, uint256 reportiD, uint256 date);

    //**** Functions ****//

    //The resource-contrained CCTV camera sends footage to cloud services via oracles for inspection
    //Any detected violation is recorded on the blockchain
    function reportViolation(string memory _reportHash) public onlyOracle nonReentrant{ 
        reportCount++;
        violationReports[reportCount] = ViolationReport(msg.sender, block.timestamp, bytes32(bytes(_reportHash)), false); //Note: the isVerified variable is only updated by the RA

        emit NewViolationReportSubmission(reportCount, msg.sender, block.timestamp, bytes32(bytes(_reportHash)));
    }

    function getViolationReport(uint256 _violationReportId) public view returns(address reporter, uint256 date, bytes32 reportDetails){
        require(_violationReportId >= 1 && _violationReportId <= reportCount, "Invalid Violation Report ID");
        ViolationReport storage report = violationReports[_violationReportId];
        return(report.oracle, report.reportingTime, report.violationReportHash);
    }

    function reviewReport(uint256 _violationReportId, bool _decision) public onlyRegulatoryAuthority{
        require(_violationReportId >= 1 && _violationReportId <= reportCount, "Invalid Violation Report ID");
        ViolationReport storage report = violationReports[_violationReportId];

        report.isVerified = _decision; //True if the RA decides the report is accurate, false otherwise

        if(_decision){
            emit ReportVerified(msg.sender, _violationReportId, block.timestamp);      
        } else {
            emit ReportRejected(msg.sender, _violationReportId, block.timestamp);
        }

    }







}
