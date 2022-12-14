// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract SpaceShipsNFTs is ERC1155, ERC2981, Ownable {

  uint256 SalvageCostDogelon = 10000000;
  uint256 SalvageCostEther   = 0.001 ether;
  uint256 private LastMintedShipID;
  address constant private _DogelonTokenContract = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
  string private _BaseURI = "";
  string private _BluePrintURI = "";
  string private _DerelictURI = "";
  address private Owner; 
  uint private OneDayInBlockHeight = 7150;
  bool private ETHMint = false;
  bool private PauseSalvageRights = false;
  uint256 private TotalShipCount;  
  mapping (uint256 => uint8) private ShipClass;
  mapping (uint256 => bool) private ShipDerelict;  
  mapping (uint256 => uint) private ReadyAtBlockHeight;
  mapping (address => bool) private SalvageRights;

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
      InitializeClasses();
      _setDefaultRoyalty(Owner, 1000);
    } 

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
      return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function SetRoyalty(address _Receiver, uint96 _RoyaltyPercentageInBasePoints) public onlyOwner {
      _setDefaultRoyalty(_Receiver, _RoyaltyPercentageInBasePoints);
    }
    
    function uri(uint256 _TokenID) override public view returns (string memory) {        
      string memory MainURI;
      if (ShipDerelict[_TokenID]) {
        MainURI = _DerelictURI;   
      } else if (block.number > ReadyAtBlockHeight[_TokenID]) {
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
    
    function GetClasses() public view returns (NewClass[] memory) {
      return Classes;
    }

    function SetBaseURI(string memory _NewURI) public onlyOwner {
      _BaseURI = _NewURI;
    }

    function SetSalvageRightsState(bool _State) public onlyOwner {
      PauseSalvageRights = _State;
    }

    function SetBluePrintURI(string memory _NewURI) public onlyOwner {
      _BaseURI = _NewURI;
    }

    function GiftSalvageRights(address _Player) public onlyOwner {
      SalvageRights[_Player] = true;
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

    function SetClassLock (bool _State, uint8 _Class) public onlyOwner {
      Classes[_Class].Unlocked = _State;
    }
    
    function GetExistingShipsNumber() public view returns (uint256) {    
      return(TotalShipCount);             
    }

    function GetClassByShipID(uint256 _ShipID) public view returns (uint8) {    
      uint8 ClassID = ShipClass[_ShipID];
      return(ClassID);             
    }

    function ChangeSalvageCosts(uint256 _Dogelon, uint256 _Ether) public onlyOwner {    
      SalvageCostDogelon = _Dogelon;
      SalvageCostEther   = _Ether;          
    }
    
    function GetSalvageCosts() public view onlyOwner returns (uint256, uint256) {    
      return(SalvageCostDogelon, SalvageCostEther);        
    }
    
    function SetShipAsDerelict(uint256 _ShipID) public onlyOwner {    
      ReadyAtBlockHeight[_ShipID] = block.timestamp;
      ShipDerelict[_ShipID] = true;     
    }
    
    function PlayerHasSalvageRights(address _Player) public view returns (bool) {    
      return(SalvageRights[_Player]);        
    } 
 
    function BuySalvageRightsDogelon() payable external {    
      if (!SalvageRights[msg.sender]) {
        require(IERC20(_DogelonTokenContract).balanceOf(msg.sender) >= SalvageCostDogelon, "Not Enough Funds!");
        IERC20(_DogelonTokenContract).transferFrom(msg.sender, Owner, SalvageCostDogelon); 
        SalvageRights[msg.sender] = true;
      }     
    }

    function BuySalvageRightsEther() payable external {   
      if (!SalvageRights[msg.sender]) {   
        require(msg.value >= SalvageCostEther, "Not Enough Funds!"); 
        payable(Owner).transfer(SalvageCostEther);  
        SalvageRights[msg.sender] = true;
      }     
    }

    function MintDerelictAndTransferOwnershipEther(uint8 _Class, address _Player) public onlyOwner {    
      if (SalvageRights[_Player]) { 
        Mint_Using_ETH(_Class);
        safeTransferFrom(msg.sender, _Player, LastMintedShipID, 1, "");
        SalvageRights[_Player] = false;  
      }
    }
    
    function MintDerelictAndTransferOwnershipDogelon(uint8 _Class, address _Player) public onlyOwner {    
      if (SalvageRights[_Player]) { 
        Mint_Using_DOGELON(_Class);
        safeTransferFrom(msg.sender, _Player, LastMintedShipID, 1, "");
        SalvageRights[_Player] = false;  
      }
    }

    function SetDerelictURI(string memory _Uri) public onlyOwner {    
      _DerelictURI = _Uri; 
    }

    function Mint_Using_ETH(uint8 _Class) public payable {   
      require(Classes[_Class].Unlocked, "Mint Is Locked For This Class!"); 
      require(ETHMint, "Mint Using ETH Is Disabled For Now, Try Using Dogelon!"); 
      require(msg.value >= Classes[_Class].ETHPrice, "Not Enough Funds!");  
      require(Classes[_Class].CurrentSupply < Classes[_Class].MaxSupply, "Max Supply Exceeded!");
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;        
      }      
      uint256 _TokenID = TotalShipCount;     
      _mint(msg.sender, _TokenID, 1, ""); 
      ShipClass[_TokenID] = _Class;
      LastMintedShipID = _TokenID;
      ReadyAtBlockHeight[_TokenID] = block.number + Classes[_Class].BuildDaysInBlockHeight;
    }

    function Mint_Using_DOGELON(uint8 _Class) public payable {
      require(Classes[_Class].Unlocked, "Mint Is Locked For This Class!");
      require(Classes[_Class].CurrentSupply < Classes[_Class].MaxSupply, "Max Supply Exceeded!");   
      require(IERC20(_DogelonTokenContract).balanceOf(msg.sender) >= Classes[_Class].DOGELONPrice, "Not Enough Funds!");  
      IERC20(_DogelonTokenContract).transferFrom(msg.sender, Owner, Classes[_Class].DOGELONPrice);      
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;          
      }     
      uint256 _TokenID = TotalShipCount;     
      _mint(msg.sender, _TokenID, 1, "");
      ShipClass[_TokenID] = _Class;
      LastMintedShipID = _TokenID;
      ReadyAtBlockHeight[_TokenID] = block.number + Classes[_Class].BuildDaysInBlockHeight;
    }

}