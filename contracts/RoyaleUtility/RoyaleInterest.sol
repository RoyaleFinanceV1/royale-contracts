// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;



interface Token{
    
     function balanceOf(address _address) external  returns (uint256);
     function transfer(address _to, uint256 _amount) external returns (bool success) ;
     function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
}


contract RoyaInterest{
    
    struct divisionDetails{
         string contractName;
         address contractAddress;
         uint256 interestPercentage;
        
    }
     
     
    mapping(uint256 => divisionDetails)  public interestDivision;
     
    uint256 public divisionCount=0;
     
    mapping(address =>uint256[]) depositedInterest;
     
    Token public tokenAddress; 
     
    address public ownerAddress;
    
   
     
     modifier onlyOwner {
      require(msg.sender == ownerAddress);
      _;
    }
    
   
    
     
     constructor(address _royatoken) public{
          tokenAddress = Token(_royatoken);
          ownerAddress=msg.sender;
     }
     
     function addDivision(string memory _name,address _contractAddress,uint256 _interestPercentage)public payable onlyOwner{
        uint256 totalPercentage;
         for(uint256 i=1;i<=divisionCount;i++){
            totalPercentage +=interestDivision[i].interestPercentage; 
         }
         require(totalPercentage+_interestPercentage<=100,"More than interest");
         divisionCount++;
         interestDivision[divisionCount].contractName= _name;
         interestDivision[divisionCount].contractAddress=_contractAddress;
         interestDivision[divisionCount].interestPercentage=_interestPercentage;
         
     }
     
     function removeDivision(uint256 _divisionID) public onlyOwner payable{
         for(uint256 i=_divisionID;i<divisionCount;i++){
             interestDivision[i].contractName=interestDivision[i+1].contractName;
             interestDivision[i].contractAddress=interestDivision[i+1].contractAddress;
             interestDivision[i].interestPercentage=interestDivision[i+1].interestPercentage;
             
        }
         delete interestDivision[divisionCount];
         divisionCount--;
     }
     
     function changeDivisionProperty(uint256 _divisionID,divisionDetails memory _newProperty)public payable onlyOwner{
         if(bytes(_newProperty.contractName).length!=0){
             interestDivision[_divisionID].contractName=_newProperty.contractName;
         }
         if(_newProperty.contractAddress!=address(0)){
             interestDivision[_divisionID].contractAddress=_newProperty.contractAddress;
         }
         if(_newProperty.interestPercentage!=0){
             interestDivision[_divisionID].interestPercentage=_newProperty.interestPercentage;
         }
         
     }
    
    function depositInterest(uint256 _amount)public payable returns(bool){
         require(_amount>0,"Interest can not be zero");
         require(tokenAddress.balanceOf(msg.sender)>=_amount,"Insufficient balance");
         depositedInterest[msg.sender].push(_amount);
         for(uint256 i=1;i<=divisionCount;i++){
           tokenAddress.transferFrom(msg.sender,interestDivision[i].contractAddress,(_amount*(interestDivision[i].interestPercentage)/100));
         }
     }
     
     function depositedInterestOf(address _address)public view returns(uint256[] memory){
         return depositedInterest[_address];
     }
    
    
}