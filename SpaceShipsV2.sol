// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceShipsNFTs is ERC1155, Ownable {
  
  address constant private _DogelonTokenContract = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
  string private _BaseURI = "";
  string private _BluePrintURI = "";
  address private Owner; 
  uint private OneDayInBlockHeight = 7150;
  bool private ETHMint = false;
  uint256 private TotalShipCount;  
  mapping (uint256 => uint8) private ShipClass;
  mapping (uint256 => uint) private ReadyAtBlockHeight;

    struct NewClass{
      uint256 ETHPrice;
      uint256 DOGELONPrice;
      uint256 MaxSupply;
      uint256 CurrentSupply;
      uint BuildDaysInBlockHeight;
      bool Unlocked;  
    }  
    NewClass[] private Classes; 

    function InitializeClasses() private {
       NewClass memory MyNewClass;
       MyNewClass.ETHPrice = 0;
       MyNewClass.DOGELONPrice = 0;
       MyNewClass.MaxSupply = 0;
       MyNewClass.BuildDaysInBlockHeight = 0;      
       Classes.push(MyNewClass);
    }

    constructor() ERC1155("") {
      Owner = msg.sender;
    }

    function uri(uint256 _TokenID) override public view returns (string memory) {        
      string memory MainURI;
      if (block.number > ReadyAtBlockHeight[_TokenID]) {
        MainURI = string(abi.encodePacked(_BaseURI, Strings.toString(_TokenID), ".json"));    
      } else {
        MainURI = _BluePrintURI;   
      }     
      return(MainURI);             
    }

    function AddNewClass(uint256 _ETHPrice, 
                         uint256 _DOGELONPrice, 
                         uint256 _MaxSupply,  
                         uint _BuildDaysInBlockHeight, 
                         bool _Unlocked) public onlyOwner { 
      uint _TempBuildDaysInBlockHeight = _BuildDaysInBlockHeight * OneDayInBlockHeight;
      NewClass memory MyNewClass;
      MyNewClass.ETHPrice               = _ETHPrice;
      MyNewClass.DOGELONPrice           = _DOGELONPrice;
      MyNewClass.MaxSupply              = _MaxSupply;
      MyNewClass.BuildDaysInBlockHeight = _TempBuildDaysInBlockHeight;   
      MyNewClass.Unlocked               = _Unlocked;
      Classes.push(MyNewClass);
    } 

    function SetBaseURI(string memory _NewURI) public onlyOwner {
      _BaseURI = _NewURI;
    }

    function SetBluePrintURI(string memory _NewURI) public onlyOwner {
      _BaseURI = _NewURI;
    }
    
    function WithdrawETH () external onlyOwner {
      payable(Owner).transfer(address(this).balance);  
    }

    function WithdrawDOGELON (uint256 _Amount) external onlyOwner {
      IERC20(_DogelonTokenContract).transfer(Owner, _Amount);
    }

    function SetETHMint (bool _State) public onlyOwner {
      ETHMint = _State;
    }
    
    function GetExistingShipsNumber() public view onlyOwner returns (uint256) {    
      return(TotalShipCount);             
    }

    function GetClassByShipID(uint256 _ShipID) public view onlyOwner returns (uint8) {    
      uint8 ClassID = ShipClass[_ShipID];
      return(ClassID);             
    }

    function Mint_Using_ETH(uint8 _Class) public payable {   
      require(_Class <= Classes.length || Classes.length > 0, "Class Not Found!"); 
      require(Classes[_Class].Unlocked, "Mint Is Locked For This Class!"); 
      require(ETHMint, "Mint Using ETH Is Disabled For Now, Try Using Dogelon!"); 
      require(msg.value >= Classes[_Class].ETHPrice, "Not Enough Funds!");  
      require(Classes[_Class].CurrentSupply < Classes[_Class].MaxSupply, "Max Supply Exceeded!");
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;        
      }      
      uint256 _TokenID = TotalShipCount;
      ShipClass[_TokenID] = _Class;
      _mint(msg.sender, _TokenID, 1, "");
      ReadyAtBlockHeight[_TokenID] = block.number + Classes[_Class].BuildDaysInBlockHeight;
    }

    function Mint_Using_DOGELON(uint8 _Class) public payable {
      require(Classes[_Class].Unlocked, "Mint Is Locked For This Class!");
      require(Classes[_Class].CurrentSupply < Classes[_Class].MaxSupply, "Max Supply Exceeded!");     
      IERC20(_DogelonTokenContract).transferFrom(msg.sender, Owner, Classes[_Class].DOGELONPrice);      
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;          
      }     
      uint256 _TokenID = TotalShipCount;
      ShipClass[_TokenID] = _Class;
      _mint(msg.sender, _TokenID, 1, "");
      ReadyAtBlockHeight[_TokenID] = block.number + Classes[_Class].BuildDaysInBlockHeight;
    }

}