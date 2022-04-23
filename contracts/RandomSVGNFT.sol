// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomSVGNFT is ERC721URIStorage, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public tokenCounter;
    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    event requestRandomSVG(bytes32 indexed requestId, uint256 indexed tokenId);
    event CreatedUnfinishedRandomSVG(
        uint256 indexed tokenId,
        uint256 randomNumber
    );

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash,
        uint256 _fee
    )
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("RandomSVG", "rsNFT")
    {
        fee = _fee;
        keyHash = _keyHash;
        tokenCounter = 0;
    }

    function create() public returns (bytes32 requestId) {
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[requestId] = tokenId;
        tokenCounter = tokenCounter + 1;
        emit requestRandomSVG(requestId, tokenId);

        //call the chainlink vrf
        //get a random number
        // use that random number to generate some random SVG code
        // base64 encode the SVG code
        // get the tokenURI and mint the NFT
    }

    //return random number
    //only vrf coordinator can call this function
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        // There is an issue!!
        // Chainlink vrf has a max gas of 200,000 (computation units)
        // chainlink just return the random number we will do the heavy lifting

        address nftOwner = requestIdToSender[requestId];
        uint256 tokenId = requestIdToTokenId[requestId];
        _safeMint(nftOwner, tokenId);

        // It is good practice to emit an event after the mapping
        tokenIdToRandomNumber[tokenId] = randomNumber;
        emit CreatedUnfinishedRandomSVG(tokenId, randomNumber);
    }

    function finishMint(uint256 tokenId) public {
        // turn that into an image URI
        // use that imageURI to format into a tokenURI

        // check to see if it's been minted and a random number is returned
        require(
            bytes(tokenURI(tokenId)).length <= 0,
            "tokenURI is already all set!!"
        );
        require(tokenCounter > tokenId, "TokenId has not been minted yet!!");
        require(
            tokenIdToRandomNumber[tokenId] > 0,
            "Need to wait for Chainlink VRF"
        );

        // generate some random svg code
    }
}
