pragma solidity ^0.4.0;
import "./AdminController.sol";

contract Mapping {
    AdminController adminController ;
    
    function Mapping(address _adminController){
        if (_adminController != 0x0 ) {
            adminController = AdminController(_adminController);
        }
        else {
            revert(); //the admin controller address is wrong
        }
    }
    modifier isAppprovedProvider (address _checkIfApproved){
        require(adminController.isState(_checkIfApproved));
        _;
    }
    modifier onlyDoctors (address _doctor){
        require(!adminController.isOrg(_doctor));
        _;
    }
    mapping (address => address[]) pendingMemberList;
    mapping (address => address[]) approvedMemberList;
    mapping (address => address[] ) withWhichProviderThisDocIsAssociated;
    event DoctorAdded(address indexed _orgAddress, address indexed _doctorAddress, uint timestamp);
    event DoctorRemoved(address indexed _orgAddress, address indexed _doctorAddress, uint timestamp);
    
    // shall be called by doctor
    function submitAttachMemberRequest (address _orgAddress)
    isAppprovedProvider(_orgAddress)
    onlyDoctors(msg.sender)
    {
        pendingMemberList[_orgAddress].push(msg.sender);
    }
    
    ///should be called by approved org only
    function approveMember (address _doctorAddress) 
    isAppprovedProvider(msg.sender) 
    onlyDoctors(_doctorAddress)
    {
        uint256 index = findIndexOfAddress(pendingMemberList[msg.sender], _doctorAddress) ; 
        require(index>=0 && index<pendingMemberList[msg.sender].length);
        approvedMemberList[msg.sender].push(_doctorAddress);
        withWhichProviderThisDocIsAssociated[_doctorAddress].push(msg.sender);
        pendingMemberList[msg.sender] = removeAddress(pendingMemberList[msg.sender],findIndexOfAddress(pendingMemberList[msg.sender], _doctorAddress));
        DoctorAdded(msg.sender, _doctorAddress, now);
    }
    
    // should be called by approved org only
    function removeMember(address _doctorAddress)
    isAppprovedProvider(msg.sender)
    onlyDoctors(_doctorAddress)
    {
        uint256 index = findIndexOfAddress(approvedMemberList[msg.sender], _doctorAddress) ; 
        require(index>=0 && index<approvedMemberList[msg.sender].length);
        approvedMemberList[msg.sender] = removeAddress(approvedMemberList[msg.sender],findIndexOfAddress(approvedMemberList[msg.sender], _doctorAddress));
        withWhichProviderThisDocIsAssociated[_doctorAddress] = removeAddress(withWhichProviderThisDocIsAssociated[_doctorAddress],findIndexOfAddress(withWhichProviderThisDocIsAssociated[_doctorAddress], msg.sender));
        DoctorRemoved(msg.sender, _doctorAddress, now);
    }
    
    // should be called by approved org only
    function getPendingMembersList()
    isAppprovedProvider(msg.sender)
    constant returns (address[]){
        return pendingMemberList[msg.sender];
    }
    
    // should be called by approved org only
    function getApprovedMembersList()
    isAppprovedProvider(msg.sender)
    constant returns (address[]){
        return approvedMemberList[msg.sender];
    }
    
    function getApprovedMembersListForAnyAddress(address _anyAddress)
    isAppprovedProvider(_anyAddress)
    constant returns (address[]){
        return approvedMemberList[_anyAddress];
    }
    
    function getOrgAddress(address _address) constant returns (address[]){
        return withWhichProviderThisDocIsAssociated[_address];
    }
    
    
    function removeAddress(address[] array, uint index) internal returns(address[] value) {
        if (index >= array.length) return;

        address[] memory arrayNew = new address[](array.length-1);
        for (uint i = 0; i<arrayNew.length; i++){
            if(i != index && i<index){
                arrayNew[i] = array[i];
            } else {
                arrayNew[i] = array[i+1];
            }
        }
        delete array;
        return arrayNew;
    }
    
    function findIndexOfAddress(address[] array, address findIndexOfThisAddress) internal  returns (uint256) {
        for (uint i = 0; i<array.length; i++){
            if( array[i] == findIndexOfThisAddress){
                break;
            }
        }
        if(i>=0 && i<array.length){
            return i;
        } else {
            return array.length;
        }
        
    }
}