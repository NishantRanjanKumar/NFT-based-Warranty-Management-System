// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct Seller {
    string name;
    address wallet;
    
}

contract Warranty is ERC721URIStorage {
    address private owner; 

    mapping(address => string) private sellers;
    address[] sellerWallets;
    mapping(address => uint[]) private customerWallets;
    mapping(uint => uint) private expirationDates;
    address[] customers;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;



    constructor() ERC721("Warranty", "wnft")  {
        owner = msg.sender;
    }

    modifier onlyOwner() {
       require(msg.sender == owner, "Permission Denied: Only contract owner can execute addSeller(address, name)");
       _;
    }

    function addSeller(address _wallet, string memory _name) external {
        require(!checkSeller(_wallet), "Runtime Error: Seller already exists.");
        require(bytes(_name).length != 0, "Runtime Error: Name must be non-empty.");
        sellers[_wallet] = _name;
        sellerWallets.push(_wallet);
    }

    function removeSeller(address _wallet) external {
        require(checkSeller(_wallet), "Runtime Error: Seller does not exist. Delete aborted.");
        uint index = 0;
        for(uint i = 0; i < sellerWallets.length; i++) {
            if(sellerWallets[index] == _wallet) {
                break;
            }   
            index++;
        }
        sellerWallets[index] = sellerWallets[sellerWallets.length - 1];
        sellerWallets.pop();
        delete sellers[_wallet];
    }

    function checkSeller(address _wallet) public view returns (bool) {
        if(keccak256(abi.encodePacked(sellers[_wallet])) == keccak256(abi.encodePacked(""))) {
            return false;
        }
        return true;
    }

    function getSellers() external view returns(Seller[] memory) {
        Seller[] memory data = new Seller[](sellerWallets.length);
        for(uint i = 0; i < sellerWallets.length; i++) {
            data[i] = Seller(sellers[sellerWallets[i]], sellerWallets[i]);
        }
        return data;
    }

    function getUserType() external view returns(string memory) {
        if(msg.sender == owner) {
            return "admin";
        }
         for(uint i = 0; i < sellerWallets.length; i++) {
            if(sellerWallets[i] == msg.sender) {
                return "seller";
            }   
        }
        return "customer";
    }

    function mintNFT(address _to, string memory _tokenURI, uint expiry) external {
        require(checkSeller(msg.sender), "Account is not a seller");
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        _mint(_to, newTokenId);
        customers.push(_to);
        expirationDates[_tokenIds.current()] = expiry;
        _setTokenURI(newTokenId, _tokenURI);
        customerWallets[_to].push(newTokenId);
    }

    function getAllTokens(address _customer) external view returns (uint[] memory) {
        return customerWallets[_customer];
    }

    function getTokenURI(address _customer, uint _tokenID) external  view returns (string memory) {
        for(uint i = 0; i < customerWallets[_customer].length; i++) {
            if(_tokenID == customerWallets[_customer][i]) {
                return tokenURI(customerWallets[_customer][i]);
            }
        }
        return "";
    }


    function burnToken() external {
        for (uint i = 1; i <= _tokenIds.current(); i++) {
            if(expirationDates[i] > 0 && block.timestamp >= expirationDates[i]) {
                for(uint j = 0; j < customers.length; j++) {
                    for(uint k = 0; k < customerWallets[customers[j]].length; i++) {
                        if( i == customerWallets[customers[j]][k]) {
                            customerWallets[customers[j]][k] = customerWallets[customers[j]][customerWallets[customers[j]].length - 1]; 
                            customerWallets[customers[j]].pop();
                            if(customerWallets[customers[j]].length == 0) {
                                delete customerWallets[customers[j]];
                                customers[j] = customers[customers.length - 1];
                                 _burn(i);
                            }
                        }
                    }
                }
               
            }
        }
    }

    function transferToken(address _from, address _to, uint _tokenId) external {
        _transfer(_from, _to, _tokenId);
        for(uint i = 0; i < customerWallets[_from].length; i++) {
            if(customerWallets[_from][i] == _tokenId) {
                customerWallets[_from][i] = customerWallets[_from][customerWallets[_from].length - 1];
                customerWallets[_from].pop();
            }
        }
        customerWallets[_to].push(_tokenId);
    }
    
    function getCurrentToken() external view returns(uint) {
        return _tokenIds.current();
    }
}