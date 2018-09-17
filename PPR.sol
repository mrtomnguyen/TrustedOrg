contract Emrify {
    
    address public owner ;
    string public name;//5
    mapping (address => uint256) public individualCount;
    
    struct AllHash{
        string AllergiesHash;//1 already present
        string MedicationHash;//2
        string ProcedureHash;//3
        string FITBITHash;//4
        string AccountHash;//5
    }
    struct RestrictedAccessUser{
        bool isAllergiesShared;
        bool isMedicationShared;
        bool isProcedureShared;
        bool isFITBITShared;
        bool isNameAllowed;
        bool isAccountHash;
    }    
    mapping(address => mapping ( address => RestrictedAccessUser)) public permission;
    mapping(address => string) public resAccUserName;
    mapping(address => AllHash) public AllRecordHashes;
    mapping(address =>  mapping ( uint256 =>string)) public notes ;
    event DocAdded(address indexed provider, address indexed patient, string msg, string attachmentHash, string textHash );

    function Emrify(){
        owner = msg.sender; // Entity X is the owner of the contract
        permission[owner][owner].isAllergiesShared = true;
        permission[owner][owner].isMedicationShared = true;
        permission[owner][owner].isProcedureShared = true;
        permission[owner][owner].isFITBITShared = true;
        permission[owner][owner].isAccountHash = true;
    }
    function setName( string _name ){
            resAccUserName[msg.sender]=_name;
            permission[msg.sender][msg.sender].isNameAllowed == true;
    }
    function setNamePerm(address _address, bool nameToggle){
        permission[msg.sender][_address].isNameAllowed = nameToggle;
    }
    
    // this address here shall come after pop-up or alert
    // here user shall choose, whether they want 
    function getName (address _address) constant returns (string ) {
        if(permission[msg.sender][_address].isNameAllowed == true ){
            return resAccUserName[msg.sender];
        }
        else {
            return "not allowed";
        }
    }
    // for his own name. 
    function getName() constant returns (string ) {
        return resAccUserName[msg.sender];
    }
    function returnOwner() constant returns (address){
        return owner;
    }
    function returnReqmaker() constant returns (address){
        return msg.sender;
    }
    
//1 setter calls   
// anyone should be able to put the record on the BC
// information shall be recorded for SELF
    function setPatientHashes(   string _AllergiesHash,
                                    string _MedicationHash,
                                    string _ProcedureHash,
                                    string _FITBITHash){
             AllRecordHashes[msg.sender].AllergiesHash =_AllergiesHash;
             AllRecordHashes[msg.sender].MedicationHash =_MedicationHash;
             AllRecordHashes[msg.sender].ProcedureHash =_ProcedureHash;
             AllRecordHashes[msg.sender].FITBITHash =_FITBITHash;
    }

    function setAccount(string _AccountHash){
        AllRecordHashes[msg.sender].AccountHash =_AccountHash;
        permission[msg.sender][msg.sender].isAccountHash = true;
        permission[msg.sender][msg.sender].isAllergiesShared = true;
        permission[msg.sender][msg.sender].isMedicationShared = true;
        permission[msg.sender][msg.sender].isProcedureShared = true;
        permission[msg.sender][msg.sender].isFITBITShared = true;
    }
    function getAccount() constant returns (string ) {
        return AllRecordHashes[msg.sender].AccountHash;
    }
    
//1 permission call
// this shall be called by patient
// so a permission must exist between a patient and a provider in question
    function SharePermission(bool isAccount, bool isAllergies, bool isMedication, 
    bool isProcedure, bool isFITBIT, address DrAddress ){
            permission[msg.sender][DrAddress].isAccountHash = isAccount;
            permission[msg.sender][DrAddress].isAllergiesShared = isAllergies;
            permission[msg.sender][DrAddress].isMedicationShared = isMedication;
            permission[msg.sender][DrAddress].isProcedureShared = isProcedure;
            permission[msg.sender][DrAddress].isFITBITShared = isFITBIT;
	}
// 4 getter caller as per the on-chain permission to check 
// wheter the permission are correctly set or not
	function getBoolAllergies (address patient,address DrAddress) constant returns (bool){
	    if (permission[patient][DrAddress].isAllergiesShared == true){
	        return true;
	    }
	    else{
	        return false;
	    }
    }
    function getBoolMedication (address patient, address DrAddress) constant returns (bool){
        if ( permission[patient][DrAddress].isMedicationShared == true){
        return true;
    }
	    else{
	        return false;
	    }
    }
    function getBoolProcedure (address patient, address DrAddress) constant returns (bool){
        if (permission[patient][DrAddress].isProcedureShared == true){
        return  true;
    }
	    else{
	        return false;
	    }
    }
    function getBoolFITBIT (address patient, address DrAddress) constant returns (bool){
        if ( permission[patient][DrAddress].isFITBITShared == true){
        return true;
    }
	    else{
	        return false;
	    }
    }
    function getBoolAccount (address patient,address DrAddress) constant returns (bool){
	    if (permission[patient][DrAddress].isAccountHash == true){
	        return true;
	    }
	    else{
	        return false;
	    }
    }
// 4 getter caller as per the on-chain permission to get the data stored   
// reason for these many getMethod calls is that, 
// currently solidity doesn't support return of array of string data type
//http://solidity.readthedocs.io/en/develop/frequently-asked-questions.html#is-it-possible-to-return-an-array-of-strings-string-from-a-solidity-function
// this shall be called by doctor. so the permission must exist between the patient
// and the doctor. Doctor shall call these 4 methods
// No third person other than the PERMISSIONED address can see this data
function getAllergies (address patient) constant  returns (string ) {
        if(permission[patient][msg.sender].isAllergiesShared == true ){
            return AllRecordHashes[patient].AllergiesHash;
        }
        else {
            return "not allowed";
        }
    }
  function getMedication (address patient) constant  returns (string ) {
        if(permission[patient][msg.sender].isMedicationShared == true){
            return AllRecordHashes[patient].MedicationHash;
        }
        else {
            return "not allowed";
        }
    }  
   function getProcedure (address patient) constant  returns (string ) {
        if(permission[patient][msg.sender].isProcedureShared == true){
            return AllRecordHashes[patient].ProcedureHash;
        }
        else {
            return "not allowed";
        }
    }
  function getFITBIT (address patient) constant returns (string ) {
        if(permission[patient][msg.sender].isFITBITShared == true){
            return AllRecordHashes[patient].FITBITHash;
        }
        else {
            return "not allowed";
        }
    } 
      function getAccountReqFromProvider (address patient) constant returns (string ) {
        if(permission[patient][msg.sender].isAccountHash == true){
            return AllRecordHashes[patient].AccountHash;
        }
        else {
            return "not allowed";
        }
    } 

    function providerNotes(string _AttachmentHash,string _TextHash,address patient, string _tag){
        notes[patient][individualCount[patient]++]= _AttachmentHash;
        notes[patient][individualCount[patient]++]= _TextHash;
        DocAdded(msg.sender, patient, _tag ,_AttachmentHash,_TextHash);
    }
    
    function getIndividualCount() constant returns ( uint256 ){
        return individualCount[msg.sender];
    }

    function fetchRecordsbyID(uint256 id)constant returns (string){
        return notes[msg.sender][id];
    }
}
