use starknet::{ContractAddress, contract_address_const};

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};
use auctioncontract::auction::{IAuctionDispatcher, IAuctionDispatcherTrait};

#[derive(Drop, Serde)]
struct AUCTIONArgs {
    seller: ContractAddress
}

const item: felt252 = 'Gold';

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let class_hash = declare(name).unwrap().contract_class();
    let mut constructor_args = array![];
    let account = contract_address_const::<'tochi'>();
    let args = AUCTIONArgs { seller: account };
    args.serialize(ref constructor_args);
    let (address, _) = class_hash.deploy(@constructor_args).unwrap();
    address
}

#[test]
fn test_registered_item() {
    let contract_address = deploy_contract("Auction");
    let auction = IAuctionDispatcher { contract_address };
    let account = contract_address_const::<'tochi'>();
    start_cheat_caller_address(contract_address, account);
    auction.register_item(item);
    assert!(auction.is_registered(item) == true, "Not Registered");
}

#[test]
fn unregister_item() {
    let contract_address = deploy_contract("Auction");
    let auction = IAuctionDispatcher { contract_address };
    assert!(auction.unregister_item(item) == true, "Not Registered");
}

#[test]
fn owner() {
    let contract_address = deploy_contract("Auction");
    let auction = IAuctionDispatcher { contract_address };
    let account = contract_address_const::<'tochi'>();
    start_cheat_caller_address(contract_address, account);
    assert!(auction.get_owner() == account, "Not a Owner");
}
