const FenumVesting = artifacts.require('FenumVesting');



module.exports = async function (deployer, network, accounts) {
  const token = "0x"; // TOKEN_ADDRESS
  const start = 1609459200;       // 2021-01-01T00:00:00.000Z = 1609459200
  const end = 1704067200;         // 2024-01-01T00:00:00.000Z = 1704067200
  const cliffDuration = 2592000;  // 30*24*60*60 = 2592000
  const args = [token, start, end, cliffDuration];
  await deployer.deploy(FenumVesting, ...args);
};
