pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;
import "./Accounts.sol";

contract CoinFlipping is AccountsManager{
    /*** structures ***/
    struct Player{
        address payable addr;
        uint number; // the number to reveal
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
    }
    
    /*** attributes ***/
    uint currentGameID;
    Game currentGame; // current game's state
    GameHistory [] gameHistory; // store game history
    Banker banker; // the banker
    
    address payable [2] players;
    mapping (address => Player) public mapPlayers;
    address payable [] honestPlayers;
    
    
    /*** constructor ***/
    constructor() public{
        // initialize game, banker
        currentGameID = 1;
        clearGame();

        banker = Banker({
            bankerAddr: 0xe29dEc2ffCf4d0A61ED9983ED5369E0EeB4A4708, // the last address offered by Ganache
            bankerName: "BANKER",
            bankerBalance: 0
        });
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
    
    function getPlayers() public view returns(address payable, address payable, string memory, string memory){
        return(players[0], players[1], accounts[players[0]].username, accounts[players[1]].username);
    }
    
    function queryByBanker() public view beBanker returns(string memory, uint){
        return(banker.bankerName, banker.bankerBalance);
    }
    
    function withdrawByBanker(uint amount) public payable beBanker{
        require(banker.bankerBalance >= amount, "Failed! You have not enough balance!");
        banker.bankerAddr.transfer(amount);
        banker.bankerBalance -= amount;
    }
    
    function joinGame() public notStartedGame notTwoPlayers{
        require(accounts[msg.sender].balance >= currentGame.bet, "Failed! You have no enough ether"); 
        players[currentGame.currentPlayers] = msg.sender;
        mapPlayers[msg.sender] = Player({
           addr: msg.sender,
           number: 0,
           hashNumber: 0,
           valid: true
        });
        currentGame.currentPlayers += 1;
    }
    
    function sendHash(bytes32 hashNumber) public ongoingGame beforeDue twoPlayers bePlayer{
        require(mapPlayers[msg.sender].hashNumber == 0, "Failed! You have already sent it!");
        mapPlayers[msg.sender].hashNumber = hashNumber;
    }
    
    function sendNumber(uint number) public ongoingGame overDue twoPlayers bePlayer{
        require(mapPlayers[msg.sender].number == 0, "Failed! You have already sent it!");
        mapPlayers[msg.sender].number = number;
    }
    
    function startGame() public notStartedGame twoPlayers beBanker{
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
        
        if (currentGame.ongoing == 2){
            return;
        }
        currentGame.ongoing = 2; // game ends.
        
        // check cheaters
        for (uint i = 0; i < currentGame.currentPlayers; i++){
            if (mapPlayers[players[i]].hashNumber == keccak256(abi.encodePacked(mapPlayers[players[i]].number))){
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
    
    function getWinner() public view endedGame returns (string memory _winnerName){
        // already checked, return result
        if (currentGame.winnerAddr == banker.bankerAddr){
            return "All cheated! No Winner!";
        }
        if (currentGame.winnerAddr != address(0)){
            return currentGame.winnerName;
        }
        return "Not checked yet!";
    }
    
    function playerGetWinner() public view endedGame returns(bool){
        if (currentGame.winnerAddr == msg.sender){
            return true;
        }
        return false;
    }
    
    function clear() public endedGame beBanker{
        // record the game to history and clear 
        gameHistory.push(GameHistory({
            gameID: currentGameID,
            player1: players[0],
            player2: players[1],
            playerName1: accounts[players[0]].username,
            playerName2: accounts[players[1]].username,
            start_time: currentGame.start_time,
            end_time: currentGame.end_time,
            winnerAddr: currentGame.winnerAddr,
            winnerName: accounts[currentGame.winnerAddr].username
        }));
        
        
        clearPlayers();
        clearGame();
        currentGameID += 1;
    }
    
    function bankerCheckHistory() public beBanker returns(GameHistory[] memory){
        return gameHistory;
    }
    
    function playerCheckHistory() public view validUser returns(GameHistory memory){
        uint len = gameHistory.length;
        for (uint i = 0; i < len; i++){
            if(gameHistory[len-i-1].player1 == msg.sender || gameHistory[len-i-1].player2 == msg.sender){
                return (gameHistory[len-i-1]);
            }
        }
        return GameHistory({
            gameID: 0,
            player1: address(0),
            player2: address(0),
            playerName1: "",
            playerName2: "",
            start_time: 0,
            end_time:0,
            winnerAddr: address(0),
            winnerName: ""
        });
    }
    
    function whoAmI() public view returns(uint){
        // return 0 for unregistered, 1 for player, 2 for banker
        if (banker.bankerAddr == msg.sender){
            return 2;
        }
        if (accounts[msg.sender].valid){
            return 1;
        }
        return 0;
    }
    
    /** private **/
    
    function clearGame() private notOngoingGame {
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
    
    function clearPlayers() private endedGame {
        // clear players' states
        for (uint i = 1; i < currentGame.currentPlayers; i++){
            delete mapPlayers[players[i]];
        }
        delete players;
        delete honestPlayers;
    }
    
}
