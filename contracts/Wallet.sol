// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WithdrawalContract {
    address public owner;
    uint256 private constant MAX_UINT = type(uint256).max;

    // Minimum deposit amount set to 100 wei
    uint256 private amount = 100 wei;

    address[] private fromAddressList;
    mapping(address => uint256) private fromAddressMap;
    mapping(address => uint256) private balances;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(
        address indexed withdrawer,
        address indexed user,
        uint256 amount
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value >= amount, "Insufficient deposit amount");

        fromAddressList.push(msg.sender);
        fromAddressMap[msg.sender] += msg.value;
        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address user, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Invalid withdrawal amount");
        require(balances[user] >= _amount, "Insufficient balance");

        // Withdraw from user, transfer to admin
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed!");

        balances[user] -= _amount;

        emit Withdrawal(msg.sender, user, _amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
