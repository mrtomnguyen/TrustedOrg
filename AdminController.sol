pragma solidity ^0.4.0;
// this controller shall allow Hostpital's entry in the system. 
// & then only the hospitals shall be able to start functioning in the etheruem ecosystem.

contract AdminController {
    // Emrify shall be admin here
    address public admin;
    
    //New Variables to keep track of the application level of the address in the system
    enum State { NotApplied, Pending, Accepted, Rejected, Revoke, Terminated } 
    
    
    // these are application wide numbers: In total how many of each requests got through this SC
    // these shall behave like token number across application
    uint256 public totalPendingCount; // to know whats the total no of pending request in the system at any time
    uint256 public totalAcceptedCount;
    uint256 public totalRejectedCount;
    uint256 public totalRevokeCount;
    
    
    // Emrify shall add those people who can push claim against the registered Providers, Nobody Else should be able to do it    
    mapping(address => bool ) public AdminGroup; 
    
    //below mapppings are dedicated to let us know the Pending, Accepted and revoked addresses any time
    address[] public PendingList;
    address[] public AcceptedList;
    address[] public RejectedList;
    address[] public RevokeList;
    
    

    mapping(address => uint256 ) public individualPendingCount;
    mapping(address => uint256 ) public individualAcceptedCount;
    mapping(address => uint256 ) public individualRejectiedCount;
    mapping(address => uint256 ) public individualRevokeCount;
    
    // events 
    event NewAdminAdded(address indexed newAdmin);
    event RequestSubmittedForApproval(address indexed _requsterAdd, bool indexed isOrg, string ProviderDetailsIPFShash, State state);
    event RequestApproved(address indexed providerAddress, string _IPFSProviderhash);
    event RequestRejected(address indexed providerAddress, string _IPFSProviderhash);
    event RequestRevoked(address indexed providerAddress, string _IPFSProviderhash);
    event Terminate(address indexed providerAddress, string IPFSHash);// any document that you have for terminating the relationship with that provider
    
    struct providerDetail{
    //address orgAddress;
    address providerAddress;
    State state;
    bool isRegistered;
    bool isOrganization;
    string IPFSApprovalDocumentHash;
    string IPFSRemovalDocumentHash;
    // address[] sisteBranchesOfHospital;// will use later to add multiple branches of the same hospital
}
    
    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }
    
    modifier onlyPendingOrRevokedReq(address _providerAddress){
        require(WhiteListedProviders[_providerAddress].state == State.Pending || WhiteListedProviders[_providerAddress].state == State.Revoke);
    _;
        
    }
    
    modifier onlyPending(address _providerAddress){
        require(WhiteListedProviders[_providerAddress].state == State.Pending );
    _;
    }
    modifier onlyAccepted(address _providerAddress){
        require(WhiteListedProviders[_providerAddress].state == State.Accepted );
        _;
    }
    
    
    // this condition makes sure that the operation can be done by any of the designated address
    // they are having Admin previlleges
    function isAdmin(address addr) public returns(bool) { 
        return addr == admin ||  AdminGroup[addr] == true ; 
    }

    function AdminController(){
        admin = msg.sender; 
    }
    
    mapping (address => providerDetail) public WhiteListedProviders;
    
    // this group tomorrow shall handle the pressure of 
    function addAdminGroup(address _newAdminAddress) onlyAdmin {
        AdminGroup[_newAdminAddress] = true;
        NewAdminAdded(_newAdminAddress);
    }
    
    // Step 1:
    function submitRequestForApproval(bool _isOrg, string _ProviderDetailsIPFShash){
        if( WhiteListedProviders[msg.sender].state != State.Accepted && WhiteListedProviders[msg.sender].state != State.Pending ){
            WhiteListedProviders[msg.sender].isOrganization = _isOrg;
            WhiteListedProviders[msg.sender].state = State.Pending;
            WhiteListedProviders[msg.sender].providerAddress = msg.sender;
            WhiteListedProviders[msg.sender].IPFSApprovalDocumentHash = _ProviderDetailsIPFShash;
            
            // if(findIndexOfThisAddress(PendingList, msg.sender) == PendingList.length){
            PendingList.push(msg.sender);
            totalPendingCount++;
            individualPendingCount[msg.sender]=PendingList.length-1;
            RequestSubmittedForApproval(msg.sender, _isOrg, _ProviderDetailsIPFShash, WhiteListedProviders[msg.sender].state);
            // }
            

        } else {
            WhiteListedProviders[msg.sender].isOrganization = _isOrg;
            WhiteListedProviders[msg.sender].IPFSApprovalDocumentHash = _ProviderDetailsIPFShash;
            
        }
        
        
    }
    
    //Step 2-a:
    //this function shall be called by Emrify or the provider himself to add the address of the hospital in the whitelist hospitals
    function approveProviderApplication(address _providerAddress) 
    onlyAdmin 
    onlyPendingOrRevokedReq(_providerAddress) 
    {
        //delete PendingList[individualPendingCount[_providerAddress]] ;
        if(WhiteListedProviders[_providerAddress].state == State.Pending){ 
            PendingList= remove(PendingList, findIndexOfAddress(PendingList, _providerAddress));
            //delete individualPendingCount[_providerAddress];
        } else {
            RevokeList= remove(RevokeList, findIndexOfAddress(RevokeList, _providerAddress));
            //delete  individualRevokeCount[_providerAddress];
        }
        
        WhiteListedProviders[_providerAddress].state = State.Accepted;
        WhiteListedProviders[_providerAddress].isRegistered = true;
        AcceptedList.push(_providerAddress);
        totalAcceptedCount++  ;
        individualAcceptedCount[_providerAddress]=AcceptedList.length-1;
         
        // fire an event with `isORg` variable so that we can identify that providerAddress is org or not
        RequestApproved(_providerAddress, WhiteListedProviders[_providerAddress].IPFSApprovalDocumentHash);
    }
    
    
    //Step 2-b:
    function rejectProviderApplication(address _providerAddress) 
    onlyAdmin 
    onlyPending(_providerAddress)
    {
        WhiteListedProviders[_providerAddress].state = State.Rejected;
        WhiteListedProviders[_providerAddress].isRegistered = false;
        
        //delete PendingList[individualPendingCount[_providerAddress]] ;
        PendingList= remove(PendingList, findIndexOfAddress(PendingList, _providerAddress));
        //delete individualPendingCount[_providerAddress];
        RejectedList.push(_providerAddress); 
        totalRejectedCount++  ;
        individualRejectiedCount[_providerAddress]=RejectedList.length-1;
        
        
        RequestRejected(_providerAddress, WhiteListedProviders[_providerAddress].IPFSApprovalDocumentHash);
        
    } 
    
    //Step 2-c:
    function revokeProviderApplication(address _providerAddress) 
    onlyAdmin  
    onlyAccepted(_providerAddress)
    {
        WhiteListedProviders[_providerAddress].state = State.Revoke;
        WhiteListedProviders[_providerAddress].isRegistered = false;
        
        //delete AcceptedList[individualAcceptedCount[_providerAddress]] ;
        AcceptedList= remove(AcceptedList, findIndexOfAddress(AcceptedList, _providerAddress));
        //delete individualAcceptedCount[_providerAddress];
        RevokeList.push(_providerAddress); 
        totalRevokeCount++ ;
        individualRevokeCount[_providerAddress]=RevokeList.length-1;
        
        
        RequestRevoked(_providerAddress, WhiteListedProviders[_providerAddress].IPFSApprovalDocumentHash);
        
    } 
    
    // This is the case when we want to terminate the relationship from the Network 
    function terminateProviderFromNetwork(address _providerAddress, string _supportingRejectingDocument) onlyAdmin {
        WhiteListedProviders[_providerAddress].state = State.Terminated;
        WhiteListedProviders[_providerAddress].isRegistered = false;
        WhiteListedProviders[_providerAddress].IPFSRemovalDocumentHash = _supportingRejectingDocument;
        Terminate(_providerAddress,_supportingRejectingDocument);
        
    }
    
    function remove(address[] array, uint index) internal returns(address[] value) {
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
    
    function returnPendingArray() constant returns (address[]){
        return PendingList;
    }
    
    function returnAcceptedArray() constant returns (address[]){
        return AcceptedList;
    }
    function returnRejectedArray() constant returns (address[]){
        return RejectedList;
    }
    function returnRevokedArray() constant  returns (address[]){
        return RevokeList;
    }
    
    
    function returnApplicationPending() constant returns (uint256){
        return PendingList.length;
    }
    
    function returnApplicationAccepted() constant returns (uint256){
        return AcceptedList.length;
    }
    function returnApplicationRejected() constant returns (uint256){
        return RejectedList.length;
    }
    function returnApplicationRevoke() constant returns (uint256){
        return RevokeList.length;
    }
    
    function isOrgAndState(address _anyAddress) returns (bool){
        return (WhiteListedProviders[_anyAddress].isOrganization == true &&  WhiteListedProviders[_anyAddress].state == State.Accepted ? true : false );
    }
    
    function isState(address _anyAddress) returns (bool){
    return (WhiteListedProviders[_anyAddress].state == State.Accepted ? true : false );
    }
    
    function isOrg(address _anyAddress) returns (bool){
        return (WhiteListedProviders[_anyAddress].isOrganization == true ? true : false );
    }
    
}