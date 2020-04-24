pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract AccountsManager {
    
    // A User
    struct User {
        string username;
        address payable addr;
        uint balance;
        bool valid; // valid or existed user
    }
    
    struct Record {
        address afrom;
        address ato;
        string ufrom;
        string uto;
        uint amount;
        uint time;
    }
    
    mapping (address => User) internal accounts; // account: an address to an user
    mapping (string => address payable) internal usernames; // username to address
    
    Record [] records; //transfer record
    
    /*** constructor ? ***/
    
    /*** events ***/
    // store the tranfer records
    // event Logger(address afrom, address ato, string ufrom, string uto, uint amount, uint time);
    event Logger(Record[] records);
    
    /*** modifiers ***/
    modifier validUser{
        require(accounts[msg.sender].valid, "Failed! You have not signed up!");
        _;
    }
    
    modifier validReceiver(address to){
        require(accounts[to].valid, "Failed! The receiver account doens't exists!");
        _;
    }
    
    modifier enoughBalance(uint amount){
        require(accounts[msg.sender].balance >= amount);
        _;
    }
    
    /*** functions ***/
    
    function create(string memory _username, address payable _addr) public payable{
        /* create an account using address
         * args:
         *  _username: account username, unique
         *  _addr: your etherum address
         * requirements:
         *  _username and _addr not already in.
         */ 
        require(accounts[_addr].valid == false, "Failed! This address has already been signed up!");
        require(usernames[_username] == address(0), "Failed, This username has already been signed up!");
        accounts[_addr] = User({
            username: _username,
            addr: _addr,
            balance: 0,
            valid: true
        });
        usernames[_username] = _addr;
    }
    
    // query for current user's username and balance
    function query() public view validUser returns(string memory, uint){
        /* query username and balance for current account
         * returns:
         *  username: string;
         *  balance: uint;
         * requirements:
         *  current user valid
         */
        return (accounts[msg.sender].username, accounts[msg.sender].balance);
    } 
    
    // deposit into contract
    function deposit() public payable validUser{
        /* deposit some money into this contract.
         * args:
         *  msg.value: amount to deposit
         * requirements:
         *  current user valid
         */
        accounts[msg.sender].balance += msg.value;
    }
    
    // withdraw balance
    function withdraw(uint amount) public payable validUser enoughBalance(amount){
        /* withdraw some money from this contract.
         * args:
         *  amount: amount to withdraw
         * requirements:
         *  current user valid
         *  enough balance
         */
        msg.sender.transfer(amount);
        accounts[msg.sender].balance -= amount;
    }
    
    // transfer using address
    function transferByAddr(address payable to, uint amount) public payable validUser validReceiver(to) enoughBalance(amount){
        /* transfer using address
         * args:
         *  to: address to transfer
         *  amount amount to transfer
         * requirements:
         *  valid sender
         *  valid receiver
         *  enough balance.
         */
        accounts[to].balance += amount;
        accounts[msg.sender].balance -= amount;
        
        // log
        records.push(Record({
            afrom: msg.sender, 
            ato: to, 
            ufrom: accounts[msg.sender].username, 
            uto: accounts[to].username, 
            amount:amount, 
            time: now
            }));
    }
    
    // transfer using username
    function transferByName(string memory to, uint amount) public payable validUser validReceiver(usernames[to]) enoughBalance(amount){
        /* transfer using ID
         * args:
         *  to: ID to transfer
         *  amount amount to transfer
         * requirements:
         *  valid sender
         *  valid receiver
         *  enough balance.
         */
        accounts[usernames[to]].balance += amount;
        accounts[msg.sender].balance -= amount;
        
        // log
        records.push(Record({
            afrom: msg.sender, 
            ato: usernames[to], 
            ufrom: accounts[msg.sender].username, 
            uto: to, 
            amount:amount, 
            time: now
            }));
    }
    
    function checkRecords() public validUser {
        emit Logger(records);
    }
    
}
