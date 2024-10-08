use core::starknet::ContractAddress;

#[starknet::interface]
pub trait IAuction<TContractState> {
    fn register_item(ref self: TContractState, item_name: felt252);

    fn unregister_item(self: @TContractState, item_name: felt252) -> bool;

    fn bid(ref self: TContractState, item_name: felt252, amount: u32);

    fn get_highest_bidder(self: @TContractState, item_name: felt252) -> u32;

    fn is_registered(self: @TContractState, item_name: felt252) -> bool;

    fn get_owner(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
pub mod Auction {
    use super::IAuction;
    use core::starknet::{
        ContractAddress, get_caller_address,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess}
    };

    #[storage]
    struct Storage {
        bid: Map<felt252, u32>,
        register: Map<felt252, bool>,
        highest_bidders: Map<felt252, u32>,
        seller: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        NewAuctionItemAdded: NewAuctionItemAdded,
        HighestBid: HighestBid,
        IsRegisteredItem: IsRegisteredItem,
    }

    #[derive(Drop, starknet::Event)]
    struct NewAuctionItemAdded {
        item_name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct HighestBid {
        item_name: felt252,
        amount: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct IsRegisteredItem {
        item_name: felt252,
        status: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState, seller: ContractAddress) {
        self.seller.write(seller);
    }

    #[abi(embed_v0)]
    impl AuctionImpl of IAuction<ContractState> {
        fn register_item(ref self: ContractState, item_name: felt252) {
            let seller = self.seller.read();
            let caller = get_caller_address();
            assert(caller == seller, 'Only seller can add item');
            
            self.register.write(item_name, true);
            self.emit(NewAuctionItemAdded { item_name });
        }

        fn unregister_item(self: @ContractState, item_name: felt252) -> bool {
            assert(self.register.read(item_name), 'unregistered item');
            self.register.read(item_name)
        }

        fn bid(ref self: ContractState, item_name: felt252, amount: u32) {
            assert(self.register.read(item_name), 'unregistered item');

            let current_highest_bid = self.bid.read(item_name);

            assert(
                amount > current_highest_bid,
                'your bid is low'
            );

            self.highest_bidders.write(item_name, amount);

            self.emit(HighestBid { item_name, amount });
        }

        fn get_highest_bidder(self: @ContractState, item_name: felt252) -> u32 {
            self.highest_bidders.read(item_name)
        }

        fn is_registered(self: @ContractState, item_name: felt252) -> bool {
            self.register.read(item_name)
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.seller.read()
        }
    }
}

