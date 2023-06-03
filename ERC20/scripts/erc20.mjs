

const Web3 = require('web3');
require('dotenv').config();

// Connect to your Ethereum provider
const web3 = new Web3('https://scroll-alphanet.public.blastapi.io');
const pK = process.env.PRIVATE_KEY;

const contractABI = [
  // Paste the ABI of your ERC20 contract here
];
const contractAddress = '0xC8EB86f06bc7ca8FeD2cE9709a80529ad30E9108';


const contract = new web3.eth.Contract(contractABI, contractAddress);


// Example function to transfer tokens
async function transferTokens(recipient, amount) {
    const accounts = await web3.eth.getAccounts();
    const sender = accounts[0];
  
    const tx = contract.methods.transfer(recipient, amount);
    const gas = await tx.estimateGas({ from: sender });
    const data = tx.encodeABI();
  
    const signedTx = await web3.eth.accounts.signTransaction(
      {
        to: contractAddress,
        data,
        gas,
        gasPrice: web3.utils.toWei('10', 'gwei'),
      },
      pK
    );
  
    const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
    console.log('Transaction receipt:', receipt);
  }

  toAddress = ""
  toAmount = 100
  // Call the transferTokens function
  transferTokens(toAddress, toAmount);
  
