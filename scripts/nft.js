const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("NFT");
  const contract = await NFT.deploy(
    "0x7DaB83cA55Db2b5635c1512984cd8ab377eB079E"
  );

  await contract.deployed();

  console.log("NFT Contract deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
