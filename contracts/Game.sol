// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Game {

    mapping(address => bool) public db;
    mapping(address => uint) public values;

    function add(address _address) public {
        db[_address] = true;
        values[_address] = random(100);
    }

   
    function getLifetimeScore(address player) public view returns(uint256){
        return values[player];
    }

    function random(uint _modulus) private view returns(uint){
        uint source = block.difficulty + block.timestamp;
        bytes memory source_b = toBytes(source);
        return uint(keccak256(source_b)) % _modulus;
    }

    function toBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

}