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
