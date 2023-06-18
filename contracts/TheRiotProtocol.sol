// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.17;

import "./RiotOrganisation.sol";

/**
 * @title TheRiotProtocol
 * @dev Contract for managing the Riot Protocol and device registration.
 * @author Gabriel Antony Xaviour
 */
contract TheRiotProtocol {
    struct Organisation {
        string name;
        address creator;
        address organisationContractAddress;
        bool exists;
    }

    uint256 private _organisationsCount;

    mapping(address => Organisation) private addressToOrganisation;

    uint256 private _createOrganisationFee;
    address private _owner;

    event OrganisationCreated(string name, address creator, address organisationContractAddress);

    constructor(uint256 _createFee) {
        _createOrganisationFee = _createFee;
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function.");
        _;
    }

    /**
     * @dev Registers a new group and adds a device.
     * @param _name The name of the Riot Organisation NFT Collection.
     * @param _symbol The symbol of the Riot Orgnaisation Devive NFT Collection.
     */
    function registerOrganisation(
        string memory _name,
        string memory _symbol,
        address _dealClientAddress
    ) public payable {
        require(msg.value >= _createOrganisationFee, "Insufficient funds");
        RiotOrganisation organisation = (new RiotOrganisation)(
            _name,
            _symbol,
            msg.sender,
            _dealClientAddress
        );
        _organisationsCount += 1;
        addressToOrganisation[address(organisation)] = Organisation(
            _name,
            msg.sender,
            address(organisation),
            true
        );
        emit OrganisationCreated(_name, msg.sender, address(organisation));
    }

    function setCreateFee(uint256 _fee) public onlyOwner {
        _createOrganisationFee = _fee;
    }

    function getCreateFee() public view returns (uint256) {
        return _createOrganisationFee;
    }

    function isRiotOrganisation(address _address) public view returns (bool) {
        return addressToOrganisation[_address].exists;
    }

    function getOrganisation(address _address) public view returns (Organisation memory) {
        return addressToOrganisation[_address];
    }
}
