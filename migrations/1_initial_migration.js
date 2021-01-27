const Migrations = artifacts.require('Migrations');



module.exports = async function (deployer, network, accounts) {
  const args = [];
  await deployer.deploy(Migrations, ...args);
};
