// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IDealClient.sol";

contract RiotOrganisation is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    struct Device {
        uint256 tokenId;
        address deviceId;
        bytes32 firmwareHash;
        bytes32 deviceDataHash;
        bytes32 deviceGroupIdHash;
        address subscriber;
        bytes32 sessionSalt;
        bool exists;
    }
    struct CreateDeviceParams {
        address deviceId;
        bytes32 firmwareHash;
        bytes32 deviceDataHash;
        bytes32 deviceGroupIdHash;
        bytes32 sessionSalt;
        string uri;
    }

    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) public isAdmin;
    mapping(address => Device) public deviceIdToDevice;
    IDealClient public dealClient;

    constructor(
        string memory name,
        string memory symbol,
        address _admin,
        address _dealClientAddress
    ) ERC721(name, symbol) {
        isAdmin[_admin] = true;
        dealClient = IDealClient(_dealClientAddress);
    }

    event DeviceCreated(uint256 indexed tokenId, address indexed owner, string uri);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    modifier onlyDevice() {
        require(deviceIdToDevice[msg.sender].exists, "Not a device");
        _;
    }

    /**
     * @dev Modifier to check if the device is minted.
     * @param _deviceId The device address to check.
     */
    modifier checkIfDeviceIsMinted(address _deviceId) {
        require(isDeviceMinted(_deviceId), "Device not minted.");
        _;
    }

    function setDealClient(address _dealClient) public onlyAdmin {
        dealClient = IDealClient(_dealClient);
    }

    function createDevice(CreateDeviceParams calldata params) public onlyAdmin {
        require(!isDeviceMinted(params.deviceId), "Device already minted.");
        uint256 _tokenId = _tokenIdCounter.current();
        Device memory newDevice = Device(
            _tokenId,
            params.deviceId,
            params.firmwareHash,
            params.deviceDataHash,
            params.deviceGroupIdHash,
            msg.sender,
            params.sessionSalt,
            true
        );
        deviceIdToDevice[params.deviceId] = newDevice;
        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, params.uri);
        _tokenIdCounter.increment();

        emit DeviceCreated(_tokenId, msg.sender, params.uri);
    }

    /**
     * @dev Sets the subscriber address for a device.
     * @param _deviceId The device address.
     * @param _subscriber The new subscriber address.
     */
    function setSubscriberAddress(
        address _deviceId,
        address _subscriber,
        bytes32 newSessionSalt
    ) public onlyAdmin {
        // Update the mappings
        deviceIdToDevice[_deviceId].subscriber = _subscriber;

        deviceIdToDevice[_deviceId].sessionSalt = newSessionSalt;
        safeTransferFrom(msg.sender, _subscriber, deviceIdToDevice[_deviceId].tokenId, "");
    }

    /**
     * @dev Updates the firmware hash for the device.
     * @param _firmwareHash The new firmware hash.
     * @param _deviceId The device address.
     */
    function updateFirmware(bytes32 _firmwareHash, address _deviceId) public onlyAdmin {
        deviceIdToDevice[_deviceId].firmwareHash = _firmwareHash;
    }

    function storeDeviceData(IDealClient.DealRequest memory deal) public onlyDevice {
        require(address(dealClient) != address(0), "DealClient not set");
        dealClient.makeDealProposal(deal);
    }

    /**
     * @dev Calculates the merkle root from an array of hashes.
     * @param hashes The array of hashes.
     * @return rootHash The merkle root hash.
     */
    function getMerkleRoot(bytes32[] memory hashes) public pure returns (bytes32) {
        require(hashes.length == 6, "Input array must have 6 elements");

        bytes32 rootHash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(hashes[0], hashes[1])),
                keccak256(abi.encodePacked(hashes[2], hashes[3])),
                keccak256(abi.encodePacked(hashes[4], hashes[5]))
            )
        );

        return rootHash;
    }

    /**
     * @dev Generates a RIOT key for a device.
     * @param _firmwareHash The firmware hash of the device.
     * @param _deviceDataHash The device data hash.
     * @param _deviceGroupIdHash The device group ID hash.
     * @param _deviceId The device address.
     * @return The RIOT key for the device.
     */
    function generateRiotKeyForDevice(
        bytes32 _firmwareHash,
        bytes32 _deviceDataHash,
        bytes32 _deviceGroupIdHash,
        address _deviceId
    ) public view checkIfDeviceIsMinted(_deviceId) returns (bytes32) {
        // Check if the received data is in the valid devices
        require(deviceIdToDevice[_deviceId].firmwareHash == _firmwareHash, "Invalid FirmwareHash");
        require(
            deviceIdToDevice[_deviceId].deviceDataHash == _deviceDataHash,
            "Invalid DeviceDataHash"
        );
        require(
            deviceIdToDevice[_deviceId].deviceGroupIdHash == _deviceGroupIdHash,
            "Invalid DeviceGroupIdHash"
        );

        bytes32[] memory hashes = new bytes32[](6);
        hashes[0] = deviceIdToDevice[_deviceId].firmwareHash;
        hashes[1] = deviceIdToDevice[_deviceId].deviceDataHash;
        hashes[2] = deviceIdToDevice[_deviceId].deviceGroupIdHash;
        hashes[3] = bytes32(bytes20(_deviceId));
        hashes[4] = bytes32(bytes20(deviceIdToDevice[_deviceId].subscriber));
        hashes[5] = deviceIdToDevice[_deviceId].sessionSalt;

        return getMerkleRoot(hashes);
    }

    /**
     * @dev Generates a RIOT key for the subscriber of a device.
     * @param _deviceId The device address.
     * @return The RIOT key for the subscriber of the device.
     */
    function generateRiotKeyForSubscriber(address _deviceId)
        public
        view
        checkIfDeviceIsMinted(_deviceId)
        returns (bytes32)
    {
        // Check if the received data is in the valid devices
        require(deviceIdToDevice[_deviceId].subscriber == msg.sender, "Unauthorized User");

        bytes32[] memory hashes = new bytes32[](6);
        hashes[0] = deviceIdToDevice[_deviceId].firmwareHash;
        hashes[1] = deviceIdToDevice[_deviceId].deviceDataHash;
        hashes[2] = deviceIdToDevice[_deviceId].deviceGroupIdHash;
        hashes[3] = bytes32(bytes20(_deviceId));
        hashes[4] = bytes32(bytes20(msg.sender));
        hashes[5] = deviceIdToDevice[_deviceId].sessionSalt;
        return getMerkleRoot(hashes);
    }

    /**
     * @dev Returns the count of registered devices.
     * @return The number of registered devices.
     */
    function getDevicesCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Returns the Device struct for a given device address.
     * @param _deviceId The device address.
     * @return The Device struct.
     */
    function getDevice(address _deviceId) public view returns (Device memory) {
        return deviceIdToDevice[_deviceId];
    }

    /**
     * @dev Checks if a device is minted.
     * @param _deviceId The device address.
     * @return A boolean indicating if the device is minted.
     */
    function isDeviceMinted(address _deviceId) public view returns (bool) {
        return deviceIdToDevice[_deviceId].exists;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
