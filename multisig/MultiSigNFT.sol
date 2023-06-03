// SPDX-License-Identifier: MIT
// [0xc473fdEa175DB122B627230AEF941c29f2cadABf, 0x8124163D6aCc56bffA5188dFdb036496de4084D6, 0x38A7aCA5E6e902837fed6fF3E6D538f7F8ae5480],2
pragma solidity ^0.8.17;
import "./erc1155.sol";

contract MultiSigWallet {
    ////////////////////////////////
    /////FACTORY STATE VARIABLES////
    ////////////////////////////////
    ERC1155Token[] public tokens; //an array that contains different ERC1155 contracts deployed
    mapping(uint256 => address) public indexToContractExecutor; //wallet that executed the transaction after confirmation

    ////////////////////////////////
    ////MULTI SIG STATE VARIABLES///
    ////////////////////////////////
    address[] public owners; //owners of the multisig contract
    mapping(address => bool) public isOwner; //mapping table whether someone is an owner or not
    uint public numConfirmationsRequired; //number of confirmation the multisig requires

    //struct for the contract confirmation
    struct ContractConfirmation {bool executed; uint numConfirmations;}
    //struct for minting confirmation
    struct MintConfirmation {bool executed; uint numConfirmations;}
    //array based on struct with data on how many owners confirmed and whether contract/mint is executed
    ContractConfirmation[] public transactionsContract;
    MintConfirmation[] public transactionsMint;
    // mapping for a transaction index(uint) to the address and then true or false, depending if owner confirmed or not.
    mapping(uint => mapping(address => bool)) public isConfirmedContract;
    mapping(uint => mapping(address => bool)) public isConfirmedMint;

    ////////////////////////////////
    ///////////CONSTRUCT////////////
    ////////////////////////////////
    //Upon creating contract we want more than zero owners 
    //and define that number of confirmations required are the same as maximum of owners
    //if true => 2 parameters: 1. array of addresses and a number for number of confirmations
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    ////////////////////////////////
    ///////////MODIFIERS////////////
    ////////////////////////////////
    //only allow owners to execute transaction
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    //check if contract/mint transaction exists, ie is in the array 'transactionsContract'.
    //2 checks: 1. doesn't exist or already executed
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactionsContract.length, "tx does not exist");
        _;
    }
    modifier notExecuted(uint _txIndex) {
        require(!transactionsContract[_txIndex].executed, "tx already executed");
        _;
    }
    modifier txMintExists(uint _txIndex) {
        require(_txIndex < transactionsMint.length, "mint tx does not exist");
        _;
    }
    modifier mintNotExecuted(uint _txIndex) {
        require(!transactionsMint[_txIndex].executed, "mint tx already executed");
        _;
    }
    //check if the transaction is already confirmed by the owner. Cant approve twice!
    modifier notConfirmedContract(uint _txIndex) {
        require(!isConfirmedContract[_txIndex][msg.sender], "contract tx already confirmed");
        _;
    }
    modifier notConfirmedMint(uint _txIndex) {
        require(!isConfirmedMint[_txIndex][msg.sender], "mint tx already confirmed");
        _;
    }

    //////////////////////////////////
    //SUBMIT/CONFIRM/CREATE FUNCTIONS/
    //////////////////////////////////
    //submit contract transaction
    //by submitting transaction, number of confirmation is autoset to 1
    //assuming that the one who proposes also agrees with the transaction
    function submitContractTransaction() public onlyOwner {
        transactionsContract.push(
            ContractConfirmation({
                executed: false,
                numConfirmations: 1
            })
        );
    }
    function submitMintTransaction() public onlyOwner {
        transactionsMint.push(
            MintConfirmation({
                executed: false,
                numConfirmations: 1
            })
        );
    }

//confirm transactions with modifiers to check for given tx ID if, tx exists, is executed and isnt already confirmed by said owner
    function confirmContractTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmedContract(_txIndex) {
        // store transactionContract struc in transactioncontract
        ContractConfirmation storage transactionContract = transactionsContract[_txIndex];
        //increment confirmation with 1 if modifiers dont fail
        transactionContract.numConfirmations += 1;
        //set owneer to confirmed in mapping table, to prevent one owner approving multiple times
        isConfirmedContract[_txIndex][msg.sender] = true;
    }

    function confirmMintTransaction(uint _txIndex) public onlyOwner txMintExists(_txIndex) mintNotExecuted(_txIndex) notConfirmedMint(_txIndex) {
        MintConfirmation storage transactionMint= transactionsMint[_txIndex];
        transactionMint.numConfirmations += 1;
        isConfirmedMint[_txIndex][msg.sender] = true;
    }
//confirm transactions with modifiers to check for given tx ID if, tx exists, is executed and isnt already confirmed by said owner
    function executeContractTransaction(
        uint _txIndex, string memory _contractName, string memory _uri, uint[] memory _ids, string[] memory _names) public onlyOwner txExists(_txIndex) 
        notExecuted(_txIndex) returns(address){
        //fetch the right transaction by passing index
        ContractConfirmation storage transactionContract = transactionsContract[_txIndex];
        //final check if for attribute numConfirmation there are enough confirmations, ie more than the minimum 
        require(
            transactionContract.numConfirmations >= numConfirmationsRequired,
            "not enough approvals for this transaction"
        );
        //after all checks create new contract
        ERC1155Token nftContract = new ERC1155Token(_contractName, _uri, _names, _ids);

        //add contract address to 'tokens' array
        tokens.push(nftContract);
        //record which owner executed the transaction
        indexToContractExecutor[tokens.length - 1] = msg.sender;
        //if the address isn't zero, then fair to assume transaction succesfull//can be removed if it fails it reverts
        require(address(nftContract) != address(0), "tx failed");
        transactionContract.executed = true;
        return address(nftContract);
    }
    function executeMintTransaction(
        uint _txIndex, uint _index, uint256 amount) public onlyOwner txMintExists(_txIndex) mintNotExecuted(_txIndex) returns(address tokenOwner){
        MintConfirmation storage transactionMint = transactionsMint[_txIndex];
        require(
            transactionMint.numConfirmations >= numConfirmationsRequired,
            "not enough approvals for this transaction"
        );
        
        tokenOwner = msg.sender;
        tokens[_index].mint(msg.sender, _index, amount);
        transactionMint.executed = true;
    }

    //////////////////////////////////
    //////////HELPER FUNCTIONS////////
    //////////////////////////////////
    function getERC1155ContractInfo(uint _index, uint _id) public view returns ( address _contract, address _owner, string memory _uri,
        uint supply)
    {   ERC1155Token token = tokens[_index];
        return (address(token), token.owner(), token.uri(_id), token.balanceOf(msg.sender, _id));
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getContractTransactionStatus(uint _txIndex) public view returns (bool executed,uint numConfirmations){
        ContractConfirmation storage transactionContract = transactionsContract[_txIndex];
        return (
            transactionContract.executed,
            transactionContract.numConfirmations
        );
    }

    function getMintTransactionStatus(uint _txIndex) public view returns (bool executed,uint numConfirmations){
        MintConfirmation storage transactionMint = transactionsMint[_txIndex];
        return (
            transactionMint.executed,
            transactionMint.numConfirmations
        );
    }
}