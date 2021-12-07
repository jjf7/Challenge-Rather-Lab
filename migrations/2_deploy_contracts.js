const Leaderboard = artifacts.require("Leaderboard");
const Game = artifacts.require("Game.sol");

module.exports = async (deployer) => {
  await deployer.deploy(Game);
  await deployer.deploy(Leaderboard);
};
