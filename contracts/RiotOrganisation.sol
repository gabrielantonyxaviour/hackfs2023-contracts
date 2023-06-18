// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDealClient {
    struct RequestId {
        bytes32 requestId;
        bool valid;
    }

    struct RequestIdx {
        uint256 idx;
        bool valid;
    }

    struct ProviderSet {
        bytes provider;
        bool valid;
    }

    struct DealRequest {
        bytes piece_cid;
        uint64 piece_size;
        bool verified_deal;
        string label;
        int64 start_epoch;
        int64 end_epoch;
        uint256 storage_price_per_epoch;
        uint256 provider_collateral;
        uint256 client_collateral;
        uint64 extra_params_version;
        ExtraParamsV1 extra_params;
    }

    struct ExtraParamsV1 {
        string location_ref;
        uint64 car_size;
        bool skip_ipni_announce;
        bool remove_unsealed_copy;
    }

    function serializeExtraParamsV1(ExtraParamsV1 memory params)
        external
        pure
        returns (bytes memory);

    function getProviderSet(bytes calldata cid) external view returns (ProviderSet memory);

    function getProposalIdSet(bytes calldata cid) external view returns (RequestId memory);

    function dealsLength() external view returns (uint256);

    function getDealByIndex(uint256 index) external view returns (DealRequest memory);

    function makeDealProposal(DealRequest calldata deal) external returns (bytes32);

    function getDealProposal(bytes32 proposalId) external view returns (bytes memory);

    function getExtraParams(bytes32 proposalId) external view returns (bytes memory);

    function authenticateMessage(bytes memory params) external view;

    function dealNotify(bytes memory params) external;

    function updateActivationStatus(bytes memory pieceCid) external;

    function addBalance(uint256 value) external;

    function withdrawBalance(address client, uint256 value) external returns (uint256);

    function receiveDataCap(bytes memory params) external;

    function handle_filecoin_method(
        uint64 method,
        uint64,
        bytes memory params
    )
        external
        returns (
            uint32,
            uint64,
            bytes memory
        );
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract RiotOrganisation {
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

    // ERC721 Variables
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => mapping(address => bool)) _operatorApprovals;

    uint256 private _tokenIdCounter;
    mapping(address => bool) public isAdmin;
    mapping(address => Device) public deviceIdToDevice;
    IDealClient public dealClient;

    constructor(
        string memory name_,
        string memory symbol_,
        address _admin,
        address _dealClientAddress
    ) {
        _name = name_;
        _symbol = symbol_;
        isAdmin[_admin] = true;
        dealClient = IDealClient(_dealClientAddress);
    }

    event DeviceCreated(uint256 indexed tokenId, address indexed owner, string uri);
    // ERC721 Events
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

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
        uint256 _tokenId = _tokenIdCounter;
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
        _owners[_tokenId] = msg.sender;
        _tokenURIs[_tokenId] = params.uri;
        _tokenIdCounter += 1;

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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not owned");
        require(to != address(0), "ERC721: transfer to the zero address");
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
        return _tokenIdCounter;
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

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    // ERC721 Getters
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _owners[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (!_isContract(to)) {
            return true;
        }
        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return true;
    }

    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
