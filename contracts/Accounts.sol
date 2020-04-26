pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract AccountsManager {
    
    // A User
    struct User {
        string username;
        address payable addr;
        uint balance;
        bool valid; // valid or existed user
        uint[] myRecords; // his/her own transfer records
        uint[] myGames; // games involving him/her
    }
    
    struct Record {
        address afrom;
        address ato;
        string ufrom;
        string uto;
        uint amount;
        uint time;
    }

    uint firstRecordID; // the first transfer record ID within one day
    uint currentRecordID; // current transfer record ID

    mapping (address => User) internal accounts; // account: an address to an user
    mapping (string => address payable) internal usernames; // username to address

    mapping (uint => Record) records; //transfer record


    /*** constructor ***/
    constructor() public{
        firstRecordID = 1;
        currentRecordID = 1;
    }

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

        accounts[_addr].username = _username;
        accounts[_addr].addr = _addr;
        accounts[_addr].valid = true;

        usernames[_username] = _addr;
    }

    function deposit() public payable validUser{
        /* deposit some money into this contract.
         * args:
         *  msg.value: amount to deposit
         * requirements:
         *  current user valid
         */
        accounts[msg.sender].balance += msg.value;

        // log
        log(msg.sender, address(0), "external wallet", accounts[msg.sender].username, msg.value, now);
    }

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

        // log
        log(msg.sender, address(0), accounts[msg.sender].username, "external wallet", amount, now);
    }

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
        log(msg.sender, to, accounts[msg.sender].username, accounts[to].username, amount, now);
    }

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
        log(msg.sender, usernames[to], accounts[msg.sender].username, to, amount, now);
    }

    /** view **/

    function query() public view validUser returns(string memory, uint){
        /* query username and balance for current account
         * return:
         *  username: string;
         *  balance: uint;
         * requirements:
         *  current user valid
         */
        return (accounts[msg.sender].username, accounts[msg.sender].balance);
    }

    function getRecordIDs() public view returns(uint[] memory) {
        /* get his/her own record IDs
         * return:
         *  recordIDs: uint[]
         */
        return accounts[msg.sender].myRecords;
    }

    function checkRecords(uint i) public view returns(uint, string memory, string memory, uint, uint){
        /* get the details of certain record by ID
         * return:
         *  from username: string
         *  to username: string
         *  amount: uint
         *  time: uint
         */
        return (i, records[i].ufrom, records[i].uto, records[i].amount, records[i].time);
    }

    /** private **/

    function log(address payable _afrom, address payable _ato, string memory _ufrom, string memory _uto, uint _amount, uint _time) internal {
        /* log current record and delete outdated records
         * args:
         *  _afrom: address, from address
         *  _ato: address, to address
         *  _ufrom: string, from username
         *  _uto: string, to username
         *  _amount: uint, transcation amount
         *  _time: uint, transcation time
         */
        records[currentRecordID] = Record({
            afrom: _afrom,
            ato: _ato,
            ufrom: _ufrom,
            uto: _uto,
            amount: _amount,
            time: _time
        });
        accounts[_afrom].myRecords.push(currentRecordID);
        accounts[_ato].myRecords.push(currentRecordID);
        currentRecordID += 1;

        for (uint i = firstRecordID; i <= currentRecordID; i++){
            if(records[i].time + 24 hours < now){
                delete records[i];
                firstRecordID += 1;
            }
        }
    }

}
