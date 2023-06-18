// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ERC1820Implementer} from "@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract Create2Deployer is Ownable, Pausable {
    function deploy(
        uint256 value,
        bytes32 salt,
        bytes memory code
    ) public whenNotPaused {
        Create2.deploy(value, salt, code);
    }

    function deployERC1820Implementer(uint256 value, bytes32 salt) public whenNotPaused {
        Create2.deploy(value, salt, type(ERC1820Implementer).creationCode);
    }

    function computeAddress(bytes32 salt, bytes32 codeHash) public view returns (address) {
        return Create2.computeAddress(salt, codeHash);
    }

    function computeAddressWithDeployer(
        bytes32 salt,
        bytes32 codeHash,
        address deployer
    ) public pure returns (address) {
        return Create2.computeAddress(salt, codeHash, deployer);
    }

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
