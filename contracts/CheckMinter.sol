//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "hardhat/console.sol";

contract CheckMinter is ERC721URIStorage {
    using Counters for Counters.Counter;

    struct Check {
        address checkWriter;
        address recipient;
        uint256 amount;
        bool spendable;
    }

    address bank;
    Counters.Counter public _tokenIds;
    mapping(uint256 => Check) public _checks;

    modifier onlyBank {
        require(msg.sender == bank, "Address is not the bank address");
        _;
    }

    constructor() ERC721("CheckFiNFT", "CKFI") {
        bank = msg.sender;
    }

    event CheckWritten(address writer, address recipient, uint256 amount);
    function writeCheck(address writer, address recipient, uint256 amount, string memory tokenURI) external onlyBank {
        // The bank mints a new NFT each time a user wants to create a check to send to another person
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(writer, newItemId);
        _setTokenURI(newItemId, tokenURI);

        // make a new Check object and then add it to the checks mapping
        Check memory newCheck = Check(writer, recipient, amount, true);
        _checks[newItemId] = newCheck;
        emit CheckWritten(writer, recipient, amount);
    }

    function endorseNewRecipient(uint tokenId, address newRecipient) public {
        _checks[tokenId].recipient = newRecipient;
    }

    function isCheckSpendable(uint256 tokenId) public view returns (bool) {
        return _checks[tokenId].spendable;
    }

    function getCheckAmount(uint256 tokenId) public view returns (uint) {
        return _checks[tokenId].amount;
    }

    function getRecipient(uint256 tokenId) public view returns (address) {
        return _checks[tokenId].recipient;

    }
    event CheckCashed(address writer, address recipient, uint256 amount);
    function cashCheck(uint256 tokenId, address recipient, uint256 amount) external onlyBank {
        // While a recipient and amount has been passed, no money is explicitly being transfered
        // from this contract, the recipient is passed to make sure the requested recipient is the
        // same one that was listed when the check was 'written' and the amount is passed to make
        // sure the amount being 'requested' is the same that was requested when the check was
        // 'written'
        require(_checks[tokenId].recipient == recipient, "Requested recipient is not original recipeint on check");
        require(isCheckSpendable(tokenId) == true, "Check has already been spent");
        require(amount == _checks[tokenId].amount, "Check amount does not match");
        _checks[tokenId].spendable = false;

        emit CheckCashed(_checks[tokenId].checkWriter, recipient, amount);
    }
}
