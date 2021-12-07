// SPDX-License-Identifier: GPL-3.0
// @author : Jose Fuentes
pragma solidity >=0.8.0;

interface IGame {
    function getLifetimeScore(address player) external view returns(uint);
}

contract Leaderboard {

    bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("getLifetimeScore(address)"));
    
    uint public max_players = 10;
    uint public count;

    address public admin;

    struct Player{
        address _address;
        uint points;
    }

    struct Board{
        address game;
        uint256 timestampBegin;
        uint256 timestampEnd;
        Player[] players;
    }

    mapping(uint => Board) public boards;
    mapping(uint => mapping(address => bool)) public playerInBoard;
    mapping(uint => uint) public playersCountByBoard;

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only Admin');
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // C R E A T E  B O A R D

    function createBoard(address game, uint256 timestampBegin, uint256 timestampEnd) public onlyAdmin{
        require(callGetLifetimeScore(game, address(this)),'This contract do not have the function needed');
        require( ((timestampEnd-timestampBegin) / 60 /60 /24) >= 10, 'The board needs to last at least 10 days');
        
        count = count + 1;
        Board storage b = boards[count];
        b.game = game;
        b.timestampBegin = timestampBegin;
        b.timestampEnd = timestampEnd;
    }

    // A D D  P L A Y E R

    function addPlayerToBoard(uint leaderboardId) external {
        require(leaderboardId >= 1 && leaderboardId <= count, 'Invalid leaderboardId');
        require(block.timestamp < boards[leaderboardId].timestampBegin, 'This Board have begun, search for another board.');
        require(playersCountByBoard[leaderboardId] < max_players, 'Number of players exccees by board');
        require(playerInBoard[leaderboardId][msg.sender] == false, 'the player is already registered');

        boards[leaderboardId].players.push(Player(msg.sender, 0));
        playerInBoard[leaderboardId][msg.sender] = true;
        playersCountByBoard[leaderboardId] = playersCountByBoard[leaderboardId] + 1;
    }


    function _getLifetimeScore(uint id, address _address) private view returns(uint) {
        IGame game = IGame(boards[id].game); 
        uint p = game.getLifetimeScore(_address);
        return p;
    }

    // U P D A T E

    function update(uint leaderboardId) public returns(Player[] memory){
        require(leaderboardId >= 1 && leaderboardId <= count, 'Invalid leaderboardId');
        require(block.timestamp <= boards[leaderboardId].timestampEnd , 'Time of the board have finished');
       
        uint countPlayers = playersCountByBoard[leaderboardId]; 

        Player[] storage newArray = boards[leaderboardId].players;
       
        for(uint i = 0; i < countPlayers; i++){
                // consultar los puntos de cada jugador 
                newArray[i].points = _getLifetimeScore(leaderboardId, newArray[i]._address);
        }
        
        Player[] memory arreglo = sort_array(newArray);

        for(uint i = 0; i < countPlayers; i++){
            newArray[i] = arreglo[i];
        }


        return newArray;

    }


    function rewards(uint leaderboardId) public view returns(uint) {
        require(leaderboardId >= 1 && leaderboardId <= count, 'Invalid leaderboardId');
        require(block.timestamp > boards[leaderboardId].timestampEnd, 'The Board is still active');

        //obtener mis recompensas
        //Recompensa = PUNTOS * (MAX_PLAYERS - POSICION) 

        uint l = boards[leaderboardId].players.length; 
        uint reward = 0;
        for(uint i = 0 ; i< l; i++ ){
            if(boards[leaderboardId].players[i]._address == msg.sender){
                reward = boards[leaderboardId].players[i].points * (l-(i+1));
            }
        }

        return reward;
    }

    function sort_array(Player[] memory arr_) public pure returns (Player[] memory){
        uint256 l = arr_.length;
        Player[] memory arr = new Player[] (l);

        for(uint i=0;i<l;i++)
        {
            arr[i] = arr_[i];
        }

        for(uint i =0;i<l;i++)
        {
            for(uint j =i+1;j<l;j++)
            {
                if(arr[i].points<arr[j].points)
                {
                    Player memory temp= arr[j];
                    arr[j]=arr[i];
                    arr[i] = temp;
                }
            }
        }
        return arr;
    }


    // Setters
    function changeAdmin(address _admin) external onlyAdmin{
        admin = _admin;
    }

    function updateMaxPlayers(uint _max_players) public onlyAdmin{
        max_players = _max_players;
    }

    // Validate smart contract function included
    function callGetLifetimeScore(address game, address _player) private returns (bool) {
        bool success;
        bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR, _player);

        assembly {
            success := call(
                gas(),            // gas remaining
                game,         // destination address
                0,              // no ether
                add(data, 32),  // input buffer (starts after the first 32 bytes in the `data` array)
                mload(data),    // input length (loaded from the first 32 bytes in the `data` array)
                0,              // output buffer
                0               // output length
            )
        }

        return success;
    }

}
