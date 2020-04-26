pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;
import "./Accounts.sol";

contract CoinFlipping is AccountsManager{
    /*** structures ***/
    struct Player{
        address payable addr;
        uint number; // the number to reveal
        uint salt;
        bytes32 hashNumber; // the hash of the number
        bool valid;
    }

    struct Game{
        // current game state
        uint ongoing; // 0 for not start yet, 1 for ongoing, 2 for already ended
        uint currentPlayers; // no. of current players
        uint bet; // bet value, 1 eth by default
        uint due; // time limit
        uint gameBalance;
        uint start_time;
        uint end_time;
        address payable winnerAddr;
        string winnerName;
    }

    struct GameHistory{
        // game states to store in history
        uint gameID;
        address payable player1;
        address payable player2;
        string playerName1;
        string playerName2;
        uint number1;
        uint number2;
        uint start_time;
        uint end_time;
        address payable winnerAddr;
        string winnerName;
    }

    struct Banker{
        // banker's state
        address payable bankerAddr;
        string bankerName;
        uint bankerBalance;
        uint[] gameIDs;
    }

    /*** attributes ***/
    uint firstGameID;  // the first game record ID within one day
    uint currentGameID;
    Game currentGame; // current game's state
    mapping (uint => GameHistory) gameHistory; // store game history
    Banker banker; // the banker

    address payable [2] players;
    mapping (address => Player) public mapPlayers;
    address payable [] honestPlayers;


    /*** constructor ***/
    constructor() public{
        // initialize game, banker
        currentGameID = 1;
        clearGame();

        banker.bankerAddr = 0xe29dEc2ffCf4d0A61ED9983ED5369E0EeB4A4708; // the last address offered by Ganache
        banker.bankerName = "BANKER";
    }


    /*** modifiers ***/
    modifier twoPlayers{
        require(currentGame.currentPlayers == 2, "Failed! No enough players!");
        _;
    }

    modifier notTwoPlayers{
        require(currentGame.currentPlayers < 2, "Failed! Already enough players!");
        _;
    }

    modifier ongoingGame{
        require(currentGame.ongoing == 1, "Failed! Game is not ongoing!");
        _;
    }

    modifier notOngoingGame{
        require(currentGame.ongoing != 1, "Failed! Game is ongoing!");
        _;
    }

    modifier notStartedGame{
        require(currentGame.ongoing == 0, "Failed! Game not started yet!");
        _;
    }

    modifier endedGame{
        require(currentGame.ongoing == 2, "Failed! Game not ended yet!");
        _;
    }

    modifier bePlayer{
        require(mapPlayers[msg.sender].valid, "Failed, You are not in the game!");
        _;
    }

    modifier beBanker{
        require(msg.sender == banker.bankerAddr, "Failed! Only banker allowed to do it!");
        _;
    }

    modifier beforeDue{
        require(now < currentGame.end_time, "Failed! Time is up!");
        _;
    }

    modifier overDue{
        require(now > currentGame.end_time, "Failed! Not due yet!");
        _;
    }


    /*** functions ***/

    /** public **/

    function withdrawByBanker(uint amount) public payable beBanker{
        /* banker withdraw his balance
         * args:
         *  amount: uint, balance amount he wants to withdraw
         */
        require(banker.bankerBalance >= amount, "Failed! You have not enough balance!");
        banker.bankerAddr.transfer(amount);
        banker.bankerBalance -= amount;
    }

    function joinGame() public notStartedGame notTwoPlayers{
        /* player join game, take out his 1 ether for be
         *
         */
        require(accounts[msg.sender].balance >= currentGame.bet, "Failed! You have no enough ether");
        require(!mapPlayers[msg.sender].valid, "Failed! You already joined the game!");
        players[currentGame.currentPlayers] = msg.sender;
        mapPlayers[msg.sender] = Player({
           addr: msg.sender,
           number: 0,
           salt: 0,
           hashNumber: 0,
           valid: true
        });
        currentGame.currentPlayers += 1;
    }

    function sendHash(bytes32 _hashNumber) public ongoingGame beforeDue twoPlayers bePlayer{
        /* player send his/her hash in the time limit
         * args:
         *  _hashNumber: bytes32, the hash to send
         */
        mapPlayers[msg.sender].hashNumber = _hashNumber;
    }

    function sendNumber(uint _number, uint _salt) public ongoingGame overDue twoPlayers bePlayer{
        /* player send his/her number and salt
         * args:
         *  _number: uint, the number to send
         *  _salt: uint, the salt to send
         */
        mapPlayers[msg.sender].number = _number;
        mapPlayers[msg.sender].salt = _salt;
    }

    function startGame() public notStartedGame twoPlayers beBanker{
        /* banker start the game if enough players
         *
         */
        currentGame.ongoing = 1;
        currentGame.start_time = now;
        currentGame.end_time = currentGame.start_time + currentGame.due;

        // transfer ether from players to banker
        for (uint i = 0; i < currentGame.currentPlayers; i++){
            accounts[players[i]].balance -= currentGame.bet;
        }
        currentGame.gameBalance += currentGame.bet * currentGame.currentPlayers;
    }


    function checkWinner() public overDue twoPlayers beBanker{
        /* banker check the hashes of both players, decide the winner and do the transfer
         *
         */

        if (currentGame.ongoing == 2){
            return;
        }
        currentGame.ongoing = 2; // game ends.

        // check cheaters
        for (uint i = 0; i < currentGame.currentPlayers; i++){
            if (mapPlayers[players[i]].hashNumber == keccak256(abi.encodePacked(mapPlayers[players[i]].number + mapPlayers[players[i]].salt))){
                honestPlayers.push(players[i]);
            }
        }

        // check winner excluding cheaters
        if (honestPlayers.length > 0){
            uint winner = 0;
            for (uint i = 0; i < honestPlayers.length; i++){
                winner += mapPlayers[honestPlayers[i]].number;
            }
            winner = winner % honestPlayers.length;
            currentGame.winnerAddr = honestPlayers[winner];
        }
        else{
            currentGame.winnerAddr = banker.bankerAddr;
        }

        // banker transfers if not
        if (msg.sender == banker.bankerAddr && currentGame.gameBalance > 0){
            // do the transfer
            if (currentGame.winnerAddr != banker.bankerAddr){
                accounts[currentGame.winnerAddr].balance += currentGame.gameBalance * 95 / 100;
                banker.bankerBalance += currentGame.gameBalance * 5 / 100;
            }
            else{
                banker.bankerBalance += currentGame.gameBalance;
            }
            currentGame.gameBalance = 0;
        }
        currentGame.winnerName = accounts[currentGame.winnerAddr].username;
    }

    function clear() public endedGame beBanker{
        /* banker record the game to history and clear current game
         *
         */
        logGame(currentGameID, players[0], players[1], accounts[players[0]].username, accounts[players[1]].username, mapPlayers[players[0]].number, mapPlayers[players[1]].number, currentGame.start_time, currentGame.end_time, currentGame.winnerAddr, accounts[currentGame.winnerAddr].username);

        clearPlayers();
        clearGame();
    }

    /** view **/

    function getOngoing() public view returns(bool){
        /* get the game state: ongoing or not
         * return:
         *  ongoing: bool
         */
        return(currentGame.ongoing == 1);
    }

    function getPlayers() public view beBanker returns(address payable, address payable, string memory, string memory){
        /* banker get the current in-game players
         * return:
         *  player1: address
         *  player2: address
         *  playerName1: uint
         *  playerName2: uint
         */
        return(players[0], players[1], accounts[players[0]].username, accounts[players[1]].username);
    }

    function queryByBanker() public view beBanker returns(string memory, uint){
        /* banker query for his balance
         * return:
         *  bankerName: string
         *  balance: uint
         */
        return(banker.bankerName, banker.bankerBalance);
    }

    function playerGetWinner() public view endedGame returns(bool){
        /* for player to check if he/she won
         * return:
         *  win: bool
         */
        if (currentGame.winnerAddr == msg.sender){
            return true;
        }
        return false;
    }

    function getWinner() public view endedGame returns (string memory){
        /* for banker to check the winner
         * return:
         *  winnerName: string
         */
        // already checked, return result
        if (currentGame.winnerAddr == banker.bankerAddr){
            return "All cheated! No Winner!";
        }
        if (currentGame.winnerAddr != address(0)){
            return currentGame.winnerName;
        }
        return "Not checked yet!";
    }

    function getGameIDs() public view returns(uint[] memory){
        /* to get the whole game IDs involving him/her
         * return:
         *  gameIDs: uint[]
         */
        if(msg.sender == banker.bankerAddr){
            return banker.gameIDs;
        }
        return accounts[msg.sender].myGames;
    }

    function checkHistory(uint i) public view returns(uint, string memory, string memory, uint, uint, uint, string memory){
        /* get the details of certain game by ID
         * return:
         *  gameID: uint
         *  playerName1: string
         *  playerName2: string
         *  number1: uint
         *  number2: uint
         *  start_time: uint
         *  end_time: uint
         *  winnerName: string
         */
        return (i, gameHistory[i].playerName1, gameHistory[i].playerName2, gameHistory[i].number1, gameHistory[i].number2, gameHistory[i].start_time, gameHistory[i].winnerName);
    }

    function whoAmI() public view returns(uint){
        /* get the role of the requester
         * return
         *  userState: bool
         */
        // return 0 for unregistered, 1 for registered, 2 for banker
        if (banker.bankerAddr == msg.sender){
            return 2;
        }
        if (accounts[msg.sender].valid){
            return 1;
        }
        return 0;
    }

    /** private **/

    function clearGame() private {
        /* for banker to reset the game
         *
         */
        // clear game's state
        currentGame = Game({
          ongoing: 0,
          currentPlayers: 0,
          bet: 1 ether,
          due: 1 minutes,
          gameBalance: 0,
          start_time: 0,
          end_time: 0,
          winnerAddr: address(0),
          winnerName: ""
        });
    }

    function clearPlayers() private {
        /* for banker to clear the players after game ended
         *
         */
        // clear players' states
        for (uint i = 0; i < 2; i++){
            delete mapPlayers[players[i]];
        }
        delete players;
        delete honestPlayers;
    }

    function logGame(uint _gameID, address payable _player1, address payable _player2, string memory _playerName1, string memory _playerName2, uint _number1, uint _number2, uint _start_time, uint _end_time, address payable _winnerAddr, string memory _winnerName) private {
        /* log current game record and delete outdated records
         * args:
         *  _gameID: uint, current game ID
         *  _player1: address, player1's address
         *  _player2: address, player2's address
         *  _playerName1: string, player1's username
         *  _playerName2: string, player2's username
         *  _number1: uint, player1's bet number
         *  _number2: uint, player2's bet number
         *  _start_time: uint, start time
         *  _end_time: uint, end time
         *  _winnerAddr: winner's address
         *  _winnerName: winner's username
         */
        gameHistory[currentGameID] = GameHistory({
            gameID: _gameID,
            player1: _player1,
            player2: _player2,
            playerName1: _playerName1,
            playerName2: _playerName2,
            number1: _number1,
            number2: _number2,
            start_time: _start_time,
            end_time: _end_time,
            winnerAddr: _winnerAddr,
            winnerName: _winnerName
        });

        accounts[_player1].myGames.push(currentGameID);
        accounts[_player2].myGames.push(currentGameID);
        banker.gameIDs.push(currentGameID);
        currentGameID += 1;

        for (uint i = firstGameID; i <= currentGameID; i++){
            if(gameHistory[i].start_time + 24 hours < now){
                delete gameHistory[i];
                firstGameID += 1;
            }
        }

    }
    
}
