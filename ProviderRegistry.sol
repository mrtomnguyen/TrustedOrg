pragma solidity ^0.4.0;
import "./AdminController.sol";


contract ProviderRegistry is AdminController {

    AdminController adminController ;
    
 /*   function addSisterHospitalInTheNetwork (address _AdminController, address _sisterHospitalAddres){
        
        if (_AdminController != 0x0) {
            adminController = AdminController(_AdminController);
            
        }
        else {
            revert();
        }
        
}*/

    // events
    event DoctorAssociated(address _orgAddress, address doctorAddress, string IPFSDocumentHash);
    event DoctorDisassociated(address _orgAddress, address doctorAddress, string IPFSDocumentHash);
    
function ProviderRegistry(address _adminController){
        if (_adminController != 0x0) {
            adminController = AdminController(_adminController);
    } else {
            revert(); //the admin controller address is wrong
        }
         
    }
    
    struct DoctorDetails{
        address doctorAddress;
        bool isRegistered ;
        string IPFSDoctorApprovalDocumentHash;
        string IPFSDoctorRemovalDocumentHash; 
    }
    
    
    mapping (address => mapping(address => DoctorDetails )) public DoctorInformation; // this mapping is to keep the relationship between the Organization and their whitelisted doctor
    
    /// this function shall be called by those hospitals which is already registered by the admin in the AdminController contract.
    function AssociateDoctorUnderMyHospital(address _doctorAddress, string _IPFSDocumentHash)   {
        if(WhiteListedProviders[msg.sender].isRegistered && WhiteListedProviders[msg.sender].isOrganization == true){
            DoctorInformation[msg.sender][_doctorAddress].doctorAddress = _doctorAddress;
            DoctorInformation[msg.sender][_doctorAddress].isRegistered = true;
            DoctorInformation[msg.sender][_doctorAddress].IPFSDoctorApprovalDocumentHash = _IPFSDocumentHash;
            DoctorAssociated(msg.sender, _doctorAddress, _IPFSDocumentHash);
        } else {
            revert();//the hospital is not registered under Emrify yet.
        }
        
    }
    
    function DisassociateDoctorfromTheHospital(address _doctorAddress, string _IPFSDocumentHash){
        if(WhiteListedProviders[msg.sender].isRegistered && WhiteListedProviders[msg.sender].isOrganization){
            if(DoctorInformation[msg.sender][_doctorAddress].isRegistered == true){
                DoctorInformation[msg.sender][_doctorAddress].isRegistered = false;
                DoctorDisassociated(msg.sender, _doctorAddress, _IPFSDocumentHash);
            } else {
                revert();//doctor already disassociated
            }
            
        } else {
            revert();//the hospital is not registered under Emrify yet.
        }
        
    }
}