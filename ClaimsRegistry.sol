pragma solidity 0.4.24;
import "./AdminController.sol";

contract ClaimsRegistry {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    
    AdminController adminController ;
   
 
   
    struct Claim {
        // uint256 accountType; // can be either individual or organzation
        uint256 claimType; // this shall be one of the many from : doctor, nurse, receptionist etc 
        //uint256 scheme; // in our case we don't need scheme as of now, as we shall be using the symmetric keys for encoding-decoding
        address issuer; // msg.sender
        address claimee;
        bytes signature; // this.address + claimType + data
        bytes data; // this is going to the hash of the data
        string uri; // the data shall reside here
        bool isApproved;
    }
    
    modifier onlyIssuer(address _issuer, bytes32 _claimId){
        Claim memory _claim = claims[_claimId];
        require(_issuer == _claim.issuer );
        _;
    }
    
     modifier onlyClaimee(address _claimee, bytes32 _claimId){
        Claim memory _claim = claims[_claimId];
        require(_claimee == _claim.claimee );
        _;
    }
    
    modifier notYourself (address _issuer){
        require(msg.sender != _issuer);
        _;
    }
    
    modifier isRequesterApproved(address _requester){
        require(adminController.isState(_requester));
        _;
    }
    
    modifier onlyApprovedOrg(address _issuerAddress){
        require( adminController.isOrgAndState(_issuerAddress)) ;
        _;
    }
    
    // [ requester ][issuer][claimType]=claimID
    mapping(address => mapping(address => mapping(uint256 => bytes32))) public pairPendingClaimPerType; // total pending claims
    
    mapping(address => mapping(address => mapping(uint256 => bytes32))) public pairApprovedClaimPerType; // my approved claims
    
    mapping(address => bytes32[])  PendingClaimsForEachIssuers; // pending claims at individual issuers
    
    mapping(address => bytes32[])  ApprovedClaimsbyEachIssuers; // claims  which are approved  by Issuers
    
    mapping(address => bytes32[])  individualPendingClaims; // pending claims for individual 
    
    mapping(address => bytes32[])  individualApprovedClaims; // approved  claims for individual 
    
    mapping (bytes32 => Claim) public claims;
    
    // mapping (bytes32 => bytes32[]) claimsByType; // either organization or individual

    constructor (address _adminController) public {
        if (_adminController != 0x0) {
            adminController = AdminController(_adminController);
        }
        else {
            revert(); //the admin controller address is wrong
        }
         
    }

    //events
    //event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed accountType, uint256  category, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, address indexed claimee, uint256 _claimType, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemovedByIssuer(bytes32 indexed claimId, address indexed claimee, uint256 _claimType, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemovedByClaimee(bytes32 indexed claimId, address indexed claimee, uint256 _claimType, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimApprovedByIssuer(bytes32 indexed claimId, address indexed claimee ,  uint256 _claimType, address indexed issuer, bytes signature, bytes data, string uri);
    // event ClaimChangedByClaimee(bytes32 indexed claimId, address indexed claimee ,  uint256 _claimType, address indexed issuer, bytes signature, bytes data, string uri);
    
    

    
    
    function getAllApprovedClaimIdsForThisIssuer (address _issuer) public view  returns (bytes32[] ){
        return ApprovedClaimsbyEachIssuers[_issuer];
    }
    
    function getAllPendingClaimIdsForThisIssuer (address _issuer) public view returns (bytes32[] ){
        return PendingClaimsForEachIssuers[_issuer];
    }
    
    function getAllApprovedClaimIdsforIndividual (address _requester) public view returns (bytes32[] ){
        return individualApprovedClaims[_requester];
    }
    
    function getAllPendingClaimIdsForIndividual (address _requester) public view returns (bytes32[] ){
        return individualPendingClaims[_requester];
    }
    // it shall add or change the claim directly. no need to check anything. it will be called by the ISSUER
    function addClaim(uint256 _claimType, address _issuer, bytes _signature, bytes _data, string _uri ) 
    notYourself(_issuer) 
    isRequesterApproved(msg.sender)
    onlyApprovedOrg(_issuer)
    public
    returns (bytes32 claimId, bool isNewClaimAdded) {
        
            claimId = keccak256(_claimType, msg.sender, _issuer); // three params: as a single claim can be uniquely identified by them
            //uint256 index = findClaimIndex(individualApprovedClaims[msg.sender], claimId);
            if(pairApprovedClaimPerType[msg.sender][_issuer][_claimType] == claimId){
                return (claimId, false);
            }
            delete claims[claimId];
             claims[claimId] = Claim(
                 {
                    //  accountType: _accountType,
                     claimType: _claimType,
                     issuer: _issuer,
                     claimee: msg.sender,
                    //  signatureType: _signatureType,
                     signature: _signature,
                     data: _data,
                     uri: _uri,
                     isApproved: false
                 }
             );
            
            if( pairPendingClaimPerType[msg.sender][_issuer][_claimType] != claimId){
                pairPendingClaimPerType[msg.sender][_issuer][_claimType]= claimId; // add to the list of the claimee
                PendingClaimsForEachIssuers[_issuer].push(claimId); // add to the list of the issuer
                individualPendingClaims[msg.sender].push(claimId);
                emit ClaimAdded(claimId, msg.sender, _claimType, _issuer, _signature, _data, _uri);
            }
                return (claimId, true);    
    }

    // shall be called by the ISSUER only
    function ApproveClaim( bytes32 _claimId )  
    onlyIssuer(msg.sender, _claimId) 
    onlyApprovedOrg(msg.sender)
    public
    returns (bool isClaimApproved)
    {
        
        Claim memory _claim = claims[_claimId];
        uint256 index = findClaimIndex(PendingClaimsForEachIssuers[msg.sender], _claimId);
        if(index < PendingClaimsForEachIssuers[msg.sender].length){
            claims[_claimId] = Claim(
                 {
                    //  accountType: _claim.accountType,
                     claimType: _claim.claimType,
                     issuer: _claim.issuer,
                     claimee: _claim.claimee,
                    //  signatureType: _signatureType,
                     signature: _claim.signature,
                     data: _claim.data,
                     uri: _claim.uri,
                     isApproved: true                 
                 }
             );
            ApprovedClaimsbyEachIssuers[msg.sender].push(_claimId);
            individualApprovedClaims[_claim.claimee].push(_claimId);
            pairApprovedClaimPerType[_claim.claimee][msg.sender][_claim.claimType]=_claimId;

            PendingClaimsForEachIssuers[msg.sender] = remove (PendingClaimsForEachIssuers[msg.sender], findClaimIndex(PendingClaimsForEachIssuers[msg.sender], _claimId));
            individualPendingClaims[_claim.claimee] = remove(individualPendingClaims[_claim.claimee], findClaimIndex(individualPendingClaims[_claim.claimee], _claimId));
            delete pairPendingClaimPerType[_claim.claimee][msg.sender][_claim.claimType];
            emit ClaimApprovedByIssuer(_claimId, msg.sender, _claim.claimType, _claim.issuer, _claim.signature, _claim.data, _claim.uri);
            return true;
        } else {
            return false;
        }
    }
    
    
    // submit a fresh request for a new claim overwriting the previous one
    // untile this gets accepted, the old one shall be active
    // This is redundant function, no need of this. because change claim is a separate fresh request for addClaim with updated params
/*    function changeClaimByClaimee(uint256 _claimType, address _issuer, bytes _signature, bytes _data, string _uri, bytes32 _claimId ) 
    onlyClaimee( msg.sender, _claimId)
    returns (bool){
        bytes32 claimId = keccak256(_claimType, msg.sender, _issuer);
        Claim memory _claim = claims[_claimId];

        if(individualApprovedClaims[msg.sender] == claimId || individualPendingClaims[msg.sender] == claimId){
                return false;
        }
        claims[_claimId] = Claim(
                 {
                    //  accountType: _claim.accountType,
                     claimType: _claim.claimType,
                     issuer: _claim.issuer,
                     claimee: _claim.claimee,
                    //  signatureType: _signatureType,
                     signature: _claim.signature,
                     data: _claim.data,
                     uri: _claim.uri,
                     isApproved: true                 
                 }
             );
        
        individualPendingClaims[msg.sender]=claimId; // add to the list of the claimee
        PendingClaimsForEachIssuers[_issuer].push(claimId); // add to the list of the issuer    
        ClaimChangedByClaimee(_claimId, msg.sender, _claim.claimType, _claim.issuer, _claim.signature, _claim.data, _claim.uri);
        
        
    }*/
    
    // shall be called by ISSUER to remove the claim
    function removeClaimByIssuer(bytes32 _claimId) 
    onlyIssuer( msg.sender, _claimId)
    onlyApprovedOrg(msg.sender)
    public
    returns (bool success) {
            Claim memory c = claims[_claimId];
            
            if(c.isApproved == true){ // must be already approved
            emit ClaimRemovedByIssuer(_claimId, c.claimee, c.claimType, c.issuer, c.signature, c.data, c.uri);
            // delete from three places: 1: issuer's approved list, 2: individual approved list, 3: from app wide claims  
            ApprovedClaimsbyEachIssuers[msg.sender] = remove (ApprovedClaimsbyEachIssuers[msg.sender], findClaimIndex(ApprovedClaimsbyEachIssuers[msg.sender], _claimId));
            individualApprovedClaims[c.claimee] = remove(individualApprovedClaims[c.claimee], findClaimIndex(individualApprovedClaims[c.claimee], _claimId));
            delete pairApprovedClaimPerType[c.claimee][msg.sender][c.claimType];
            delete claims[_claimId];
            
            return true;
        }
        else {
            return false;       
        }
    }        
    
    
    // shall be called by individual entity
    function removeSelfClaim(bytes32 _claimId)
    isRequesterApproved(msg.sender)
    onlyClaimee( msg.sender, _claimId)
    public
    returns (bool success) {
            Claim memory c = claims[_claimId];
             if(c.isApproved == true){ // must be already approved
            emit ClaimRemovedByClaimee(_claimId, c.claimee, c.claimType, c.issuer, c.signature, c.data, c.uri);
            // delete from three places: 1: issuer's approved list, 2: individual approved list, 3: from app wide claims  
            ApprovedClaimsbyEachIssuers[c.issuer] = remove (ApprovedClaimsbyEachIssuers[c.issuer], findClaimIndex(ApprovedClaimsbyEachIssuers[c.issuer], _claimId));
            individualApprovedClaims[c.claimee] = remove(individualApprovedClaims[c.claimee], findClaimIndex(individualApprovedClaims[c.claimee], _claimId));
            delete pairApprovedClaimPerType[msg.sender][c.issuer][c.claimType];
            delete claims[_claimId];
            
            return true;
        }
        else {
            return false;       
        }
                 
    }
        
    
        
    function remove(bytes32[] array, uint index) internal pure returns(bytes32[] value) {
        // if (index >= array.length) return;

        bytes32[] memory arrayNew = new bytes32[](array.length-1);
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
    
    function findClaimIndex(bytes32[] _claimIds, bytes32 findThisClaim) internal pure returns (uint256){
        for (uint256 i = 0; i<_claimIds.length; i++){
             if( _claimIds[i] == findThisClaim){
                break;
            }
        }
        if(i>=0 && i<_claimIds.length){
            return i;
        } else {
            return _claimIds.length;
        }
    }
    
}