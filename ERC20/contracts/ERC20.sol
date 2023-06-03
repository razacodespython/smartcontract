// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";

contract ERC20 is IERC20 {

    /////////STATE VARIABLES///////
    //reminder to self: type visibility name
    address public owner; //owner of the contract
    uint public totalSupply; //totalsupply of the contract
    mapping(address => uint) public balanceOf; //balance of the caller
    mapping(address => mapping(address => uint)) public allowance; //
    string public name = "PRACTISE"; //name of the ERC20 token
    string public symbol = "PRT"; // Symbol of the erc 20 toke 
    uint8 public decimals = 18; //decimals of the token

    //////////CONSTRUCTOR///////////
    constructor(uint _totalSupply) {
        owner = msg.sender; // set owner of the contract to address deploying the smartcontract
        totalSupply = _totalSupply; //constructor takes totalSupply as param, when deployed send to deployer address
        balanceOf[owner] = totalSupply; // set the balance of owner equal to total supply
        emit Transfer(address(0), owner, totalSupply);
    }

    ///////////MODIFIERS////////////
    //only allow owners to execute transaction
    modifier onlyOwner() {
        require(msg.sender== owner); //only owner can call this function
        _;
    }
    

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external onlyOwner {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
